require "test_helper"

class SiteAndDomainTest < ActiveSupport::TestCase
  setup do
    @site = create_site(name: "Кофейня")
  end

  test "normalises a hostname the way a Host header would arrive" do
    domain = @site.domains.create!(host: "  Example.COM.  ")

    assert_equal "example.com", domain.host
  end

  test "refuses a hostname that is not one" do
    assert_not @site.domains.new(host: "not a domain").valid?
    assert_not @site.domains.new(host: "http://example.com").valid?
    assert_not @site.domains.new(host: "example").valid?
  end

  test "a host belongs to one site only" do
    @site.domains.create!(host: "example.com")
    other = create_site(name: "Другой")

    assert_not other.domains.new(host: "example.com").valid?,
               "two sites claiming one host would make routing ambiguous"
  end

  test "promoting a domain demotes the previous primary" do
    first = @site.domains.create!(host: "one.example", primary: true)
    second = @site.domains.create!(host: "two.example")

    second.make_primary!

    assert second.reload.primary
    assert_not first.reload.primary
  end

  test "rejects a slug that would not survive being put in a URL" do
    assert_not Site.new(name: "X", slug: "Привет").valid?
    assert_not Site.new(name: "X", slug: "with space").valid?
    assert Site.new(name: "X", slug: "coffee-shop").valid?
  end
end
