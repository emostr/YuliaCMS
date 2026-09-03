require "test_helper"

class BlockRendererTest < ActiveSupport::TestCase
  setup do
    @site = create_site(name: "Кофейня")
    @renderer = Yulia::BlockRenderer.new(site: @site)
  end

  test "renders every built-in block without raising" do
    Yulia::BlockRegistry.all.each_value do |definition|
      html = @renderer.render(
        { "id" => "b", "type" => definition.key, "props" => definition.defaults }
      )

      assert_not_includes html, "could not be rendered",
                          "built-in block #{definition.key} failed to render"
    end
  end

  test "escapes text a visitor would otherwise execute" do
    html = @renderer.render(block(:heading, text: "<script>alert(1)</script>"))

    assert_not_includes html, "<script>"
    assert_includes html, "&lt;script&gt;"
  end

  test "escapes a quoted attribute so markup cannot be broken out of" do
    html = @renderer.render(block(:button, label: "Жми", href: %q{" onmouseover="steal()}))

    assert_not_includes html, 'onmouseover="steal()'
  end

  test "sanitises rich text rather than trusting the editor" do
    html = @renderer.render(block(:text, html: "<p>Текст<script>alert(1)</script></p>"))

    assert_includes html, "<p>Текст</p>"
    assert_not_includes html, "alert"
  end

  test "an unknown block leaves a hidden note instead of breaking the page" do
    html = @renderer.render(block(:does_not_exist))

    assert_includes html, "unknown block"
    assert_includes html, "hidden", "a visitor must not see the note"
  end

  test "one broken block does not stop the others rendering" do
    broken = @site.block_types.create!(
      key: "broken", name: "Сломанный", kind: "html",
      template: "{% for %}", schema: []
    )

    renderer = Yulia::BlockRenderer.new(site: @site)
    html = renderer.render({ "id" => "x", "type" => broken.key, "props" => {} })

    assert_includes html, "hidden"
    assert_includes @renderer.render(block(:heading, text: "Цел")), "Цел"
  end

  test "a custom template cannot reach Ruby" do
    hostile = @site.block_types.create!(
      key: "hostile", name: "Проверка", kind: "html",
      # Liquid has no way to call this; if it ever rendered, the output would
      # contain the class name of the Rails application.
      template: "{{ site.class }}|{% assign x = 1 %}{{ x }}",
      schema: []
    )

    renderer = Yulia::BlockRenderer.new(site: @site)
    html = renderer.render({ "id" => "x", "type" => hostile.key, "props" => {} })

    assert_includes html, "|1"
    assert_not_includes html, "Yulia::Application"
  end

  test "a Svelte block renders as a mount point carrying its props" do
    island = @site.block_types.create!(
      key: "counter", name: "Счётчик", kind: "svelte",
      build_status: "ready", asset_path: "/yulia/islands/1/counter.js",
      schema: [ { "key" => "title", "type" => "text" } ],
      source: "<div></div>"
    )

    renderer = Yulia::BlockRenderer.new(site: @site)
    html = renderer.render(
      { "id" => "i", "type" => island.key, "props" => { "title" => "Привет" } }
    )

    assert_includes html, 'data-yulia-island="counter"'
    assert_includes html, "Привет"
  end

  test "a Svelte block that has not been built yet is not placed on the page" do
    @site.block_types.create!(
      key: "pending", name: "Ждёт", kind: "svelte", build_status: "pending",
      schema: [], source: "<div></div>"
    )

    renderer = Yulia::BlockRenderer.new(site: @site)
    html = renderer.render({ "id" => "i", "type" => "pending", "props" => {} })

    assert_includes html, "unknown block"
  end

  test "reports which islands a set of blocks needs" do
    @site.block_types.create!(
      key: "counter", name: "Счётчик", kind: "svelte", build_status: "ready",
      asset_path: "/x.js", schema: [], source: "<div></div>"
    )

    renderer = Yulia::BlockRenderer.new(site: @site)
    islands = renderer.islands_for([
      block(:heading, text: "Раз"),
      { "id" => "i", "type" => "counter", "props" => {} }
    ])

    assert_equal [ "counter" ], islands.map(&:key)
  end
end
