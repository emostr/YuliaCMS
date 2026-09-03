# Signing in to the admin panel.
#
# The session cookie holds a random token; the database keeps only its digest.
# Two things must be true before a request counts as authenticated: the token
# matches a live session, and the account behind it has enrolled a second
# factor. The second condition is what makes the factor mandatory rather than
# merely offered - an account that skipped enrolment can reach the enrolment
# endpoints and nothing else.
module Authentication
  extend ActiveSupport::Concern

  COOKIE = :yulia_session

  included do
    before_action :restore_session
    helper_method :signed_in?, :current_user if respond_to?(:helper_method)
  end

  private

    def restore_session
      Current.session = Session.authenticate(cookies.signed[COOKIE])
      Current.ip_address = request.remote_ip
      Current.user_agent = request.user_agent
    end

    def current_user = Current.user

    def signed_in? = Current.session.present?

    # Fully signed in: authenticated *and* carrying a second factor.
    def require_authentication
      return render_unauthorized unless signed_in?
      return render_second_factor_required unless current_user.second_factor_enrolled?

      true
    end

    # For the enrolment endpoints, which by definition run before the factor
    # exists.
    def require_password_authentication
      render_unauthorized unless signed_in?
    end

    def sign_in(user)
      session_record, token = Session.start!(
        user: user,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      Current.session = session_record

      cookies.signed[COOKIE] = {
        value: token,
        httponly: true,
        secure: request.ssl?,
        same_site: :lax,
        expires: session_record.expires_at
      }
      session_record
    end

    def sign_out
      Current.session&.destroy
      Current.session = nil
      cookies.delete(COOKIE)
    end

    def render_unauthorized
      render json: { error: "unauthorized" }, status: :unauthorized
    end

    def render_second_factor_required
      render json: { error: "second_factor_required" }, status: :forbidden
    end
end
