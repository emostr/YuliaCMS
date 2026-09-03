require "test_helper"

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  test "the first visit offers setup, and only once" do
    get api_setup_path
    assert_response :success
    assert JSON.parse(response.body)["needs_setup"]

    post api_setup_path, params: {
      setup: {
        email: "owner@example.com", name: "Владелец",
        password: "correct horse battery staple",
        password_confirmation: "correct horse battery staple"
      }
    }, as: :json
    assert_response :created

    get api_setup_path
    assert_not JSON.parse(response.body)["needs_setup"]

    # A server left running for a day must not let a passer-by claim it.
    post api_setup_path, params: {
      setup: { email: "thief@example.com", name: "Чужой",
               password: "another very long password",
               password_confirmation: "another very long password" }
    }, as: :json
    assert_response :conflict
  end

  test "a password alone does not open a session once a factor exists" do
    user = create_enrolled_user

    post api_session_path,
         params: { session: { email: user.email, password: "correct horse battery staple" } },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body["challenge"].present?, "the password step must hand back a challenge"
    assert_nil body["user"]

    # The session is not open yet.
    get api_sites_path
    assert_response :unauthorized
  end

  test "the second factor completes the sign-in" do
    user = create_enrolled_user

    post api_session_path,
         params: { session: { email: user.email, password: "correct horse battery staple" } },
         as: :json
    challenge = JSON.parse(response.body)["challenge"]

    post second_factor_api_session_path,
         params: { challenge: challenge, code: ROTP::TOTP.new(user.otp_secret).now },
         as: :json
    assert_response :success

    get api_sites_path
    assert_response :success
  end

  test "a wrong code does not open a session" do
    user = create_enrolled_user

    post api_session_path,
         params: { session: { email: user.email, password: "correct horse battery staple" } },
         as: :json
    challenge = JSON.parse(response.body)["challenge"]

    post second_factor_api_session_path,
         params: { challenge: challenge, code: "000000" }, as: :json
    assert_response :unauthorized

    get api_sites_path
    assert_response :unauthorized
  end

  test "a forged challenge is refused" do
    create_enrolled_user

    post second_factor_api_session_path,
         params: { challenge: "made-up", code: "123456" }, as: :json

    assert_response :unauthorized
    assert_equal "challenge_expired", JSON.parse(response.body)["error"]
  end

  test "an unknown address and a wrong password are told apart by nobody" do
    create_enrolled_user(email: "real@example.com")

    post api_session_path,
         params: { session: { email: "real@example.com", password: "wrong" } }, as: :json
    known = [ response.status, JSON.parse(response.body)["error"] ]

    post api_session_path,
         params: { session: { email: "nobody@example.com", password: "wrong" } }, as: :json
    unknown = [ response.status, JSON.parse(response.body)["error"] ]

    assert_equal known, unknown,
                 "differing answers would turn this endpoint into a list of accounts"
  end

  test "an account without a second factor can only reach the enrolment endpoints" do
    user = create_user

    post api_session_path,
         params: { session: { email: user.email, password: "correct horse battery staple" } },
         as: :json
    assert_response :success
    assert_equal "enrol_second_factor", JSON.parse(response.body)["next"]

    get api_sites_path
    assert_response :forbidden
    assert_equal "second_factor_required", JSON.parse(response.body)["error"]

    post totp_api_second_factor_path
    assert_response :success
    assert JSON.parse(response.body)["qr_svg"].present?
  end

  test "enrolment is only accepted once a real code proves the app works" do
    user = create_user
    post api_session_path,
         params: { session: { email: user.email, password: "correct horse battery staple" } },
         as: :json

    post totp_api_second_factor_path
    secret = JSON.parse(response.body)["secret"]

    post confirm_totp_api_second_factor_path, params: { code: "000000" }, as: :json
    assert_response :unprocessable_content
    assert_not user.reload.second_factor_enrolled?

    post confirm_totp_api_second_factor_path,
         params: { code: ROTP::TOTP.new(secret).now }, as: :json
    assert_response :success
    assert user.reload.second_factor_enrolled?
    assert_equal User::RECOVERY_CODE_COUNT, JSON.parse(response.body)["recovery_codes"].size
  end

  test "signing out ends the session" do
    user = create_enrolled_user
    post api_session_path,
         params: { session: { email: user.email, password: "correct horse battery staple" } },
         as: :json
    post second_factor_api_session_path,
         params: { challenge: JSON.parse(response.body)["challenge"],
                   code: ROTP::TOTP.new(user.otp_secret).now }, as: :json

    delete api_session_path
    assert_response :success

    get api_sites_path
    assert_response :unauthorized
  end
end

class RussianContentTest < ActionDispatch::IntegrationTest
  # A regression guard for the whole path, not just the helper: creating a site
  # with a Russian name used to fail validation before it reached the database.
  setup do
    @user = create_enrolled_user
    post api_session_path,
         params: { session: { email: @user.email, password: "correct horse battery staple" } },
         as: :json
    post second_factor_api_session_path,
         params: { challenge: JSON.parse(response.body)["challenge"],
                   code: ROTP::TOTP.new(@user.otp_secret).now }, as: :json
  end

  test "a site with a Russian name can be created" do
    post api_sites_path, params: { site: { name: "Кофейня «Пар»" } }, as: :json

    assert_response :created
    assert_equal "kofeynya-par", JSON.parse(response.body).dig("site", "slug")
  end

  test "two sites with the same Russian name get different addresses" do
    post api_sites_path, params: { site: { name: "Кофейня" } }, as: :json
    first = JSON.parse(response.body).dig("site", "slug")

    post api_sites_path, params: { site: { name: "Кофейня" } }, as: :json
    assert_response :created
    assert_not_equal first, JSON.parse(response.body).dig("site", "slug")
  end

  test "a page with a Russian title can be created" do
    post api_sites_path, params: { site: { name: "Сайт" } }, as: :json
    site_id = JSON.parse(response.body).dig("site", "id")

    post api_site_pages_path(site_id), params: { page: { title: "О нас" } }, as: :json

    assert_response :created
    assert_equal "/o-nas", JSON.parse(response.body).dig("page", "path")
  end
end
