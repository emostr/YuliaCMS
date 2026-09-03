require "test_helper"

class PublicSiteTest < ActionDispatch::IntegrationTest
  setup do
    @site = create_site(name: "Кофейня", slug: "coffee")
    @site.domains.create!(host: "coffee.example", primary: true)

    @home = create_page(site: @site, title: "Кофейня", content: [
      block(:hero, id: "h", title: "Кофейня", subtitle: "Обжариваем сами")
    ])
    @home.publish!
  end

  test "serves the site to the host that claims it" do
    get "/", headers: { "HOST" => "coffee.example" }

    assert_response :success
    assert_includes response.body, "Обжариваем сами"
  end

  test "a host nobody claims does not reach any site" do
    get "/", headers: { "HOST" => "stranger.example" }

    # Falls through to the admin panel, which is not built in the test tree.
    assert_not_includes response.body.to_s, "Обжариваем сами"
  end

  test "an unknown path answers 404 rather than the home page" do
    get "/nowhere", headers: { "HOST" => "coffee.example" }

    assert_response :not_found
  end

  test "a draft page is not visible to a visitor" do
    create_page(site: @site, title: "Секрет", slug: "secret", home: false,
                content: [ block(:heading, text: "Не готово") ])

    get "/secret", headers: { "HOST" => "coffee.example" }

    assert_response :not_found
  end

  test "a page with no interactive block loads no JavaScript at all" do
    plain = create_page(site: @site, title: "О нас", slug: "about", home: false,
                        content: [ block(:heading, text: "О нас") ])
    plain.publish!

    get "/about", headers: { "HOST" => "coffee.example" }

    assert_response :success
    assert_not_includes response.body, "<script",
                        "a page of text must not pay for a JavaScript runtime"
  end

  test "a page with a form block loads htmx" do
    form = create_page(site: @site, title: "Контакты", slug: "contacts", home: false,
                       content: [ block(:form, id: "f", title: "Напишите", fields: []) ])
    form.publish!

    get "/contacts", headers: { "HOST" => "coffee.example" }

    assert_includes response.body, "/yulia/htmx.min.js"
  end

  test "canonical points at the primary domain" do
    get "/", headers: { "HOST" => "coffee.example" }

    assert_includes response.body, %q{<link rel="canonical" href="https://coffee.example/">}
  end

  test "preview shows a draft only to someone signed in" do
    draft = create_page(site: @site, title: "Черновик", slug: "draft", home: false,
                        content: [ block(:heading, text: "Только для своих") ])

    get "/preview/coffee/draft"
    assert_response :not_found

    user = create_enrolled_user
    post api_session_path,
         params: { session: { email: user.email, password: "correct horse battery staple" } },
         as: :json
    post second_factor_api_session_path,
         params: { challenge: JSON.parse(response.body)["challenge"],
                   code: ROTP::TOTP.new(user.otp_secret).now }, as: :json

    get "/preview/coffee/draft"
    assert_response :success
    assert_includes response.body, "Только для своих"
    assert_equal "Черновик", draft.reload.title
  end
end
