require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "stores the address downcased so one person cannot hold two accounts" do
    user = create_user(email: "Owner@Example.COM")

    assert_equal "owner@example.com", user.email
    assert_raises(ActiveRecord::RecordInvalid) { create_user(email: "OWNER@example.com") }
  end

  test "rejects a password short enough to be guessed" do
    user = User.new(email: "short@example.com", name: "X", password: "short")

    assert_not user.valid?
    # Asserted on the attribute rather than the wording: the wording is
    # translated, and the test should not break when a locale file changes.
    assert_includes user.errors.attribute_names, :password
  end

  test "is not considered protected until a factor is actually confirmed" do
    user = create_user

    assert_not user.second_factor_enrolled?

    user.begin_totp_enrolment!
    assert_not user.second_factor_enrolled?,
               "a secret that was never confirmed must not count as enrolment"

    user.confirm_totp!(ROTP::TOTP.new(user.otp_secret).now)
    assert user.second_factor_enrolled?
  end

  test "accepts a code from the neighbouring time step because phone clocks drift" do
    user = create_user
    user.begin_totp_enrolment!
    totp = ROTP::TOTP.new(user.otp_secret)

    assert user.verify_totp(totp.at(30.seconds.ago))
    assert user.verify_totp(totp.now)
  end

  test "refuses a code from far outside the window" do
    user = create_user
    user.begin_totp_enrolment!

    assert_not user.verify_totp(ROTP::TOTP.new(user.otp_secret).at(10.minutes.ago))
    assert_not user.verify_totp("000000")
    assert_not user.verify_totp("")
  end

  test "issues a fresh secret if enrolment is restarted" do
    user = create_user
    first = user.begin_totp_enrolment!
    second = user.begin_totp_enrolment!

    assert_not_equal first, second,
                     "an abandoned enrolment must not stay usable by whoever saw the old QR"
  end

  test "keeps only digests of recovery codes" do
    user = create_user
    codes = user.regenerate_recovery_codes!

    assert_equal User::RECOVERY_CODE_COUNT, codes.size
    codes.each do |code|
      assert_not_includes user.recovery_codes, code,
                          "the plain code must never be written to the database"
    end
  end

  test "spends a recovery code on use" do
    user = create_user
    codes = user.regenerate_recovery_codes!

    assert user.consume_recovery_code(codes.first)
    assert_not user.consume_recovery_code(codes.first), "a code must not work twice"
    assert_equal User::RECOVERY_CODE_COUNT - 1, user.recovery_codes.size
  end

  test "locks the account after repeated failures and reports it" do
    user = create_user

    (User::MAX_FAILED_ATTEMPTS - 1).times { user.register_failed_attempt! }
    assert_not user.locked?

    user.register_failed_attempt!
    assert user.locked?

    user.register_successful_login!
    assert_not user.locked?
    assert_equal 0, user.failed_attempts
  end

  test "encrypts the TOTP secret at rest" do
    user = create_user
    secret = user.begin_totp_enrolment!

    stored = User.connection.select_value(
      "SELECT otp_secret FROM users WHERE id = #{user.id}"
    )

    assert_not_equal secret, stored,
                     "a database dump must not hand over a working second factor"
    assert_equal secret, user.reload.otp_secret
  end
end
