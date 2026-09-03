require "test_helper"

class SlugTest < ActiveSupport::TestCase
  # Rails' own parameterize reduces a Russian title to an empty string, which
  # made it impossible to create a site with a Russian name - that is, almost
  # every site Yulia exists to build.
  test "transliterates Cyrillic instead of discarding it" do
    assert_equal "kofeynya-par", Yulia::Slug.from("Кофейня «Пар»")
    assert_equal "schi-da-kasha", Yulia::Slug.from("Щи да каша")
    assert_equal "obyavleniya", Yulia::Slug.from("Объявления")
    assert_equal "ezhik", Yulia::Slug.from("Ёжик")
  end

  test "leaves Latin titles alone" do
    assert_equal "hello-world", Yulia::Slug.from("Hello World")
  end

  test "always returns something usable" do
    assert_equal "page", Yulia::Slug.from("!!!")
    assert_equal "page", Yulia::Slug.from("")
    assert_equal "page", Yulia::Slug.from(nil)
    assert_equal "site", Yulia::Slug.from("---", fallback: "site")
  end

  test "does not hand out a name the router already uses" do
    Yulia::Slug::RESERVED.each do |reserved|
      assert_not_equal reserved, Yulia::Slug.from(reserved),
                       "#{reserved.inspect} would shadow a built-in route"
    end
  end

  test "produces a slug a URL and the model will both accept" do
    [ "Кофейня «Пар»", "Щи да каша", "Hello World", "Ёжик", "!!!" ].each do |title|
      slug = Yulia::Slug.from(title)

      assert_match(/\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/, slug, "#{title.inspect} gave #{slug.inspect}")
      assert Site.new(name: title, slug: slug).valid?, "#{slug.inspect} was rejected by Site"
    end
  end

  test "keeps the slug short enough to live in a path" do
    assert_operator Yulia::Slug.from("Очень " * 100).length, :<=, 80
  end

  test "appends a number when the name is taken" do
    taken = %w[kofeynya-par kofeynya-par-2]

    assert_equal "kofeynya-par-3",
                 Yulia::Slug.unique("Кофейня «Пар»") { |candidate| taken.include?(candidate) }
  end

  test "leaves the first one unnumbered" do
    assert_equal "kofeynya-par", Yulia::Slug.unique("Кофейня «Пар»") { |_| false }
  end
end
