require "test_helper"

class EditorApiTest < ActionDispatch::IntegrationTest
  # These guard shapes that strong parameters cannot describe. Every one of
  # them was silently dropping data before: the editor could not save a page,
  # a site could not keep its menu, and a custom block could not keep its fields.

  setup do
    @user = create_enrolled_user
    post api_session_path,
         params: { session: { email: @user.email, password: "correct horse battery staple" } },
         as: :json
    post second_factor_api_session_path,
         params: { challenge: JSON.parse(response.body)["challenge"],
                   code: ROTP::TOTP.new(@user.otp_secret).now }, as: :json

    post api_sites_path, params: { site: { name: "Кофейня" } }, as: :json
    @site_id = JSON.parse(response.body).dig("site", "id")

    get api_site_pages_path(@site_id)
    @page_id = JSON.parse(response.body)["pages"].first["id"]
  end

  test "saves a page of blocks with nested props" do
    blocks = [
      { id: "h1", type: "hero",
        props: { title: "Кофейня", subtitle: "Обжариваем сами", align: "center" } },
      { id: "g1", type: "gallery",
        props: { columns: "3",
                 images: [ { src: "/a.jpg", alt: "А" }, { src: "/b.jpg", alt: "Б" } ] } }
    ]

    patch api_page_path(@page_id), params: { page: { draft_content: blocks } }, as: :json

    assert_response :success
    saved = JSON.parse(response.body).dig("page", "draft_content")

    assert_equal 2, saved.size
    assert_equal "Кофейня", saved.first.dig("props", "title")
    assert_equal 2, saved.second.dig("props", "images").size,
                 "nested arrays of objects must survive the round trip"
    assert_equal "/a.jpg", saved.second.dig("props", "images", 0, "src")
  end

  test "renaming a page does not disturb its blocks" do
    patch api_page_path(@page_id),
          params: { page: { draft_content: [ { id: "h", type: "heading", props: { text: "Раз" } } ] } },
          as: :json

    patch api_page_path(@page_id), params: { page: { title: "Новое имя" } }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "Новое имя", body.dig("page", "title")
    assert_equal 1, body.dig("page", "draft_content").size
  end

  test "refuses a block that is not one" do
    patch api_page_path(@page_id), params: { page: { draft_content: [
      { id: "ok", type: "heading", props: { text: "Годный" } },
      { id: "", type: "heading", props: {} },
      { id: "no-type", props: {} },
      { id: "hostile", type: "../../etc/passwd", props: {} },
      "not a block at all"
    ] } }, as: :json

    assert_response :success
    saved = JSON.parse(response.body).dig("page", "draft_content")

    assert_equal 1, saved.size, "only the well-formed block should survive"
    assert_equal "ok", saved.first["id"]
  end

  test "publishing puts the saved draft live" do
    patch api_page_path(@page_id),
          params: { page: { draft_content: [ { id: "h", type: "heading", props: { text: "Живое" } } ] } },
          as: :json
    assert JSON.parse(response.body).dig("page", "has_unpublished_changes")

    post publish_api_page_path(@page_id)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "published", body.dig("page", "status")
    assert_not body.dig("page", "has_unpublished_changes")
    assert_equal "Живое", Page.find(@page_id).live_content.first.dig("props", "text")
  end

  test "keeps the site menu, which is a list of objects" do
    patch api_site_path(@site_id), params: { site: { navigation: [
      { label: "Главная", href: "/" },
      { label: "О нас", href: "/about" }
    ] } }, as: :json

    assert_response :success
    menu = JSON.parse(response.body).dig("site", "navigation")

    assert_equal 2, menu.size
    assert_equal "Главная", menu.first["label"]
    assert_equal "/about", menu.second["href"]
  end

  test "keeps a custom block's field definitions" do
    post api_site_block_types_path(@site_id), params: { block_type: {
      key: "hours", name: "Часы работы", kind: "html",
      template: "<p>{{ block.title }}</p>",
      schema: [
        { key: "title", label: "Заголовок", type: "text" },
        { key: "note", label: "Примечание", type: "textarea" }
      ]
    } }, as: :json

    assert_response :created
    fields = JSON.parse(response.body).dig("block_type", "fields")

    assert_equal 2, fields.size
    assert_equal "title", fields.first["key"]
    assert_equal "Примечание", fields.second["label"]
  end

  test "the first domain added becomes the primary one" do
    post api_site_domains_path(@site_id), params: { domain: { host: "par.example" } }, as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "par.example", body.dig("domain", "host")
    assert body.dig("domain", "primary"), "a site's only domain must be its canonical one"
  end
end
