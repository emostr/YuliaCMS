require "test_helper"

class PageTest < ActiveSupport::TestCase
  setup do
    @site = create_site
  end

  test "serves nothing publicly until it is published" do
    page = create_page(site: @site, content: [ block(:heading, text: "Привет") ])

    assert_equal [], page.live_content
    assert_not page.published?
  end

  test "publishing copies the draft, and later edits do not leak to visitors" do
    page = create_page(site: @site, content: [ block(:heading, id: "h", text: "Первый") ])
    page.publish!

    assert_equal "Первый", page.live_content.first.dig("props", "text")

    page.save_draft!([ block(:heading, id: "h", text: "Черновик") ])

    assert_equal "Первый", page.reload.live_content.first.dig("props", "text"),
                 "an unfinished edit must not reach the published page"
    assert_equal "Черновик", page.draft_blocks.first.dig("props", "text")
  end

  test "knows when publishing would change anything" do
    page = create_page(site: @site, content: [ block(:heading, text: "Раз") ])
    page.publish!

    assert_equal page.draft_blocks, page.live_content

    page.save_draft!([ block(:heading, text: "Два") ])
    assert_not_equal page.draft_blocks, page.live_content
  end

  test "snapshots the previous draft before overwriting it" do
    page = create_page(site: @site, content: [ block(:heading, text: "Старое") ])

    assert_difference -> { page.revisions.count }, 1 do
      page.save_draft!([ block(:heading, text: "Новое") ])
    end

    assert_equal "Старое", page.revisions.first.content.first.dig("props", "text")
  end

  test "restores the published version back into the draft" do
    page = create_page(site: @site, content: [ block(:heading, text: "Живое") ])
    page.publish!
    page.save_draft!([ block(:heading, text: "Ошибка") ])

    page.restore_published_into_draft!

    assert_equal "Живое", page.reload.draft_blocks.first.dig("props", "text")
  end

  test "keeps history bounded" do
    page = create_page(site: @site, content: [ block(:heading, text: "0") ])

    (Page::MAX_REVISIONS + 10).times { |i| page.save_draft!([ block(:heading, text: i.to_s) ]) }

    assert_operator page.revisions.count, :<=, Page::MAX_REVISIONS
  end

  test "derives the path from the slug, and the home page owns the root" do
    home = create_page(site: @site)
    about = create_page(site: @site, title: "О нас", slug: "about", home: false)

    assert_equal "/", home.path
    assert_equal "/about", about.path
  end

  test "allows only one home page per site" do
    create_page(site: @site)
    second = @site.pages.new(title: "Ещё", slug: "another", home: true)

    assert_not second.valid?
    assert_includes second.errors[:home].join, "another page"
  end

  test "does not allow two pages on the same path" do
    create_page(site: @site, title: "О нас", slug: "about", home: false)
    clash = @site.pages.new(title: "Другая", slug: "about", home: false)

    assert_not clash.valid?
  end
end
