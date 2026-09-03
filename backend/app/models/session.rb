# A signed-in browser.
#
# The cookie carries a random token; the database keeps only its digest, so a
# stolen dump cannot be turned into a working session.
class Session < ApplicationRecord
  belongs_to :user

  scope :active, -> { where(expires_at: Time.current..) }
  scope :expired, -> { where(expires_at: ...Time.current) }

  # Returns the session together with the token to hand to the browser. The
  # token exists in the clear only inside this method's return value.
  def self.start!(user:, ip_address: nil, user_agent: nil)
    token = SecureRandom.urlsafe_base64(32)
    session = create!(
      user: user,
      token_digest: digest(token),
      ip_address: ip_address,
      user_agent: user_agent.to_s.first(255),
      expires_at: Yulia.session_days.days.from_now
    )
    [ session, token ]
  end

  def self.authenticate(token)
    return nil if token.blank?

    active.find_by(token_digest: digest(token))
  end

  def self.digest(token)
    OpenSSL::Digest::SHA256.hexdigest("yulia-session:#{token}")
  end

  # Housekeeping for expired rows; a session that has lapsed is worthless.
  def self.sweep! = expired.delete_all
end
