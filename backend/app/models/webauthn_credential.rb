# A passkey registered against an account: the alternative to TOTP.
#
# What is stored is a public key, so this table holds nothing that could be
# replayed to impersonate the user.
class WebauthnCredential < ApplicationRecord
  belongs_to :user

  validates :external_id, presence: true, uniqueness: true
  validates :public_key, presence: true

  # An authenticator increments a counter on every use. A value that fails to
  # advance suggests the credential has been cloned, so the sign-in is refused.
  def register_use!(new_sign_count)
    if new_sign_count.to_i.positive? && new_sign_count.to_i <= sign_count
      raise Yulia::ClonedCredentialError, "sign count did not advance for credential #{id}"
    end

    update!(sign_count: new_sign_count, last_used_at: Time.current)
  end
end
