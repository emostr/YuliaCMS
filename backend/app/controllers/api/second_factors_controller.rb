module Api
  # Enrolling the second factor.
  #
  # Reachable with a password alone, because this is where an account that has
  # no factor yet comes to get one. Every other API endpoint requires the
  # factor to already exist.
  class SecondFactorsController < ApplicationController
    before_action :require_password_authentication

    def show
      render json: {
        enrolled: current_user.second_factor_enrolled?,
        totp: current_user.totp_enrolled?,
        passkeys: current_user.webauthn_credentials.count,
        recovery_codes_left: current_user.recovery_codes.size
      }
    end

    # Issues a secret and the QR code that carries it. Calling this again before
    # confirmation replaces the secret, so an enrolment someone abandoned - and
    # photographed - cannot be picked up later.
    def totp
      secret = current_user.begin_totp_enrolment!
      uri = current_user.totp_provisioning_uri

      render json: {
        secret: secret,
        uri: uri,
        # Rendered here rather than in the browser so that the secret never has
        # to be handled by client-side code.
        qr_svg: RQRCode::QRCode.new(uri).as_svg(module_size: 4, use_path: true, viewbox: true)
      }
    end

    # Proves the authenticator actually works before the factor is switched on.
    # Confirming on trust would lock people out of their own installation.
    def confirm_totp
      if current_user.confirm_totp!(params[:code].to_s)
        render json: {
          enrolled: true,
          recovery_codes: current_user.regenerate_recovery_codes!
        }
      else
        render json: { error: "invalid_code" }, status: :unprocessable_content
      end
    end

    def recovery_codes
      render json: { recovery_codes: current_user.regenerate_recovery_codes! }
    end
  end
end
