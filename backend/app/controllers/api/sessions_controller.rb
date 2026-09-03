module Api
  # Signing in, in two steps.
  #
  # The password alone never produces a session. It produces a short-lived
  # challenge, which the second factor then redeems. The one exception is an
  # account that has not enrolled a factor yet: it is signed in immediately,
  # but Authentication#require_authentication keeps it away from everything
  # except the enrolment endpoints.
  class SessionsController < ApplicationController
    skip_before_action :require_authentication, raise: false

    CHALLENGE_VALIDITY = 5.minutes

    # Guessing passwords should be slow no matter how many accounts are tried,
    # so the limit is on the caller, not on the account.
    rate_limit to: 10, within: 3.minutes, only: :create,
               with: -> { render json: { error: "too_many_attempts" }, status: :too_many_requests }

    rate_limit to: 20, within: 3.minutes, only: :second_factor,
               with: -> { render json: { error: "too_many_attempts" }, status: :too_many_requests }

    def show
      return render json: { signed_in: false, csrf_token: form_authenticity_token } unless signed_in?

      render json: {
        signed_in: true,
        csrf_token: form_authenticity_token,
        user: serialize(current_user)
      }
    end

    def create
      user = User.find_by(email: params.dig(:session, :email).to_s.strip.downcase)

      # The same answer whether the address is unknown or the password is wrong:
      # a different one would turn this endpoint into a list of who has an account.
      unless user&.authenticate(params.dig(:session, :password).to_s)
        user&.register_failed_attempt!
        return render json: { error: "invalid_credentials" }, status: :unauthorized
      end

      if user.locked?
        return render json: { error: "locked", until: user.locked_until }, status: :locked
      end

      if user.second_factor_enrolled?
        render json: {
          challenge: issue_challenge(user),
          methods: available_methods(user)
        }
      else
        # No factor yet - let them in far enough to enrol one.
        user.register_successful_login!
        sign_in(user)
        render json: { user: serialize(user), next: "enrol_second_factor" }
      end
    end

    def second_factor
      user = redeem_challenge(params[:challenge])
      return render json: { error: "challenge_expired" }, status: :unauthorized unless user
      return render json: { error: "locked", until: user.locked_until }, status: :locked if user.locked?

      unless verify_factor(user)
        user.register_failed_attempt!
        return render json: { error: "invalid_code" }, status: :unauthorized
      end

      user.register_successful_login!
      sign_in(user)
      render json: { user: serialize(user) }
    end

    def destroy
      sign_out
      render json: { signed_in: false }
    end

    private

      def verify_factor(user)
        code = params[:code].to_s
        return true if user.verify_totp(code)

        # A recovery code is spent on use, so a stolen list shrinks as it is used.
        user.consume_recovery_code(code)
      end

      def available_methods(user)
        methods = []
        methods << "totp" if user.totp_enrolled?
        methods << "passkey" if user.webauthn_credentials.any?
        methods << "recovery" if user.recovery_codes.any?
        methods
      end

      # A signed, expiring note saying "this account proved its password".
      # Nothing is written to the database, so an abandoned sign-in leaves no
      # half-open session behind.
      def issue_challenge(user)
        Rails.application.message_verifier(:yulia_second_factor)
             .generate({ user_id: user.id }, expires_in: CHALLENGE_VALIDITY)
      end

      def redeem_challenge(token)
        payload = Rails.application.message_verifier(:yulia_second_factor).verified(token.to_s)
        payload && User.find_by(id: payload[:user_id] || payload["user_id"])
      end

      def serialize(user)
        { id: user.id, email: user.email, name: user.name, role: user.role,
          second_factor_enrolled: user.second_factor_enrolled? }
      end
  end
end
