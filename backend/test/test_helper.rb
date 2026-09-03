ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Deliberately not parallelised. Each worker wants its own database, and on
    # a Postgres running inside a small VM the setup reliably cost more than the
    # whole suite takes to run serially.

    fixtures :all

    # Builders used across the suite. Tests read better when the noise of
    # creating a valid site is one call rather than six lines.

    def create_user(email: nil, password: "correct horse battery staple", **attributes)
      User.create!(
        email: email || "owner-#{SecureRandom.hex(4)}@example.com",
        name: "Владелец",
        password: password,
        password_confirmation: password,
        **attributes
      )
    end

    # A user who has finished enrolling a second factor, which is what every
    # authenticated endpoint requires.
    def create_enrolled_user(**attributes)
      user = create_user(**attributes)
      user.begin_totp_enrolment!
      user.update!(otp_confirmed_at: Time.current)
      user
    end

    def create_site(name: "Проба", slug: nil, **attributes)
      Site.create!(name: name, slug: slug || "site-#{SecureRandom.hex(4)}", **attributes)
    end

    def create_page(site:, title: "Главная", slug: "home", home: true, content: [], **attributes)
      site.pages.create!(
        title: title, slug: slug, home: home, draft_content: content, **attributes
      )
    end

    def block(type, id: SecureRandom.uuid, **props)
      { "id" => id, "type" => type.to_s, "props" => props.transform_keys(&:to_s) }
    end
  end

  # Helpers for tests that drive the application over HTTP.
  class IntegrationTest < ActionDispatch::IntegrationTest
    # Signs in the way a browser would: password, then the second factor.
    def sign_in(user, password: "correct horse battery staple")
      post api_session_path, params: { session: { email: user.email, password: password } },
                             as: :json

      body = JSON.parse(response.body)
      return unless body["challenge"]

      code = ROTP::TOTP.new(user.otp_secret).now
      post second_factor_api_session_path,
           params: { challenge: body["challenge"], code: code }, as: :json
    end
  end
end
