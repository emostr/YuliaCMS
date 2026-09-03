# Someone who signs in to the admin panel.
#
# Every account must carry a second factor. A password alone is never enough to
# reach the admin, because the admin can deploy code to every site on the box.
# The factor is enrolled on first sign-in rather than at creation time, so that
# the installer does not have to render a QR code in a terminal.
class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :webauthn_credentials, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :sites, through: :memberships

  # A TOTP secret is as good as a password: anyone holding it can mint valid
  # codes forever. Encrypted at rest so a database dump does not hand it over.
  encrypts :otp_secret

  ROLES = %w[owner editor].freeze

  # Wrong passwords are cheap to try, so an account pauses after this many.
  MAX_FAILED_ATTEMPTS = 10
  LOCKOUT = 15.minutes

  RECOVERY_CODE_COUNT = 10

  normalizes :email, with: ->(value) { value.to_s.strip.downcase }

  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: "does not look like an address" }
  validates :role, inclusion: { in: ROLES }
  validates :password, length: { minimum: 12 }, allow_nil: true

  scope :owners, -> { where(role: "owner") }

  def owner? = role == "owner"

  # --- Second factor ---------------------------------------------------------

  def second_factor_enrolled?
    otp_confirmed_at.present? || webauthn_credentials.any?
  end

  def totp_enrolled? = otp_confirmed_at.present?

  # Hands back a secret to show as a QR code. Calling this again before the
  # factor is confirmed issues a fresh secret, so an abandoned enrolment cannot
  # be resumed by someone who photographed the earlier code.
  def begin_totp_enrolment!
    update!(otp_secret: ROTP::Base32.random, otp_confirmed_at: nil)
    otp_secret
  end

  def totp_provisioning_uri
    return nil if otp_secret.blank?

    ROTP::TOTP.new(otp_secret, issuer: "Yulia").provisioning_uri(email)
  end

  # Accepts codes from the adjacent time steps too: phone clocks drift, and
  # refusing a code the user is reading off the screen is its own kind of bug.
  def verify_totp(code)
    return false if otp_secret.blank? || code.blank?

    ROTP::TOTP.new(otp_secret).verify(code.to_s.gsub(/\s/, ""), drift_behind: 30, drift_ahead: 30).present?
  end

  def confirm_totp!(code)
    return false unless verify_totp(code)

    update!(otp_confirmed_at: Time.current)
    true
  end

  # --- Recovery codes --------------------------------------------------------

  # Returned in the clear exactly once, at generation. Only digests are stored,
  # so losing the phone means using a code, not reading one out of the database.
  def regenerate_recovery_codes!
    codes = Array.new(RECOVERY_CODE_COUNT) { SecureRandom.alphanumeric(10).downcase }
    update!(recovery_codes: codes.map { |code| self.class.digest_recovery_code(code) })
    codes
  end

  # Each code works once: a used one is struck from the list as it is spent.
  def consume_recovery_code(code)
    digest = self.class.digest_recovery_code(code.to_s.strip.downcase)
    return false unless recovery_codes.include?(digest)

    update!(recovery_codes: recovery_codes - [ digest ])
    true
  end

  def self.digest_recovery_code(code)
    OpenSSL::Digest::SHA256.hexdigest("yulia-recovery:#{code}")
  end

  # --- Lockout ---------------------------------------------------------------

  def locked? = locked_until.present? && locked_until.future?

  def register_failed_attempt!
    attempts = failed_attempts + 1
    if attempts >= MAX_FAILED_ATTEMPTS
      update!(failed_attempts: 0, locked_until: LOCKOUT.from_now)
    else
      update!(failed_attempts: attempts)
    end
  end

  def register_successful_login!
    update!(failed_attempts: 0, locked_until: nil, last_login_at: Time.current)
  end
end
