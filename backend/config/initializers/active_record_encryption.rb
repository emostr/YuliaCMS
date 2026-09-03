# Active Record encryption normally wants three secrets of its own, kept in
# credentials. Yulia is installed by people who are not developers, so asking
# for four secrets instead of one would be four chances to lose the site.
#
# Instead the keys are derived from SECRET_KEY_BASE, which the installer already
# generates. Same guarantee, one secret to back up. Rotating SECRET_KEY_BASE
# therefore also invalidates encrypted columns - which, for the TOTP secrets
# stored here, means enrolling the second factor again.
Rails.application.configure do
  generator = ActiveSupport::KeyGenerator.new(
    Rails.application.secret_key_base,
    hash_digest_class: OpenSSL::Digest::SHA256
  )

  config.active_record.encryption.primary_key =
    generator.generate_key("yulia/active-record-encryption/primary", 32)

  config.active_record.encryption.deterministic_key =
    generator.generate_key("yulia/active-record-encryption/deterministic", 32)

  config.active_record.encryption.key_derivation_salt =
    generator.generate_key("yulia/active-record-encryption/salt", 32)
end
