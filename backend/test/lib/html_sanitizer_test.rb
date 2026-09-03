require "test_helper"

class HtmlSanitizerTest < ActiveSupport::TestCase
  test "keeps the formatting the editor can produce" do
    html = "<p>Текст <strong>жирный</strong> и <em>курсив</em></p><ul><li>пункт</li></ul>"

    assert_equal html, Yulia::HtmlSanitizer.rich_text(html)
  end

  test "removes a script tag along with the code inside it" do
    result = Yulia::HtmlSanitizer.rich_text("<p>Привет<script>alert(1)</script></p>")

    assert_equal "<p>Привет</p>", result
    assert_not_includes result, "alert"
  end

  test "removes inline event handlers" do
    result = Yulia::HtmlSanitizer.rich_text(%q{<p onclick="steal()">Текст</p>})

    assert_not_includes result, "onclick"
    assert_includes result, "Текст"
  end

  test "removes a javascript: link" do
    result = Yulia::HtmlSanitizer.rich_text(%q{<a href="javascript:alert(1)">клик</a>})

    assert_not_includes result, "javascript:"
  end

  test "keeps the LaTeX a formula carries" do
    html = %q{<span data-latex="\frac{1}{2}" data-type="formula"></span>}

    assert_includes Yulia::HtmlSanitizer.rich_text(html), "data-latex"
  end

  test "keeps an embed from a host known to serve players" do
    html = %q{<iframe src="https://www.youtube.com/embed/abc"></iframe>}

    assert_includes Yulia::HtmlSanitizer.embed(html), "youtube.com/embed/abc"
  end

  test "drops an iframe pointing anywhere else" do
    html = %q{<iframe src="https://evil.example/phish"></iframe>}

    assert_not_includes Yulia::HtmlSanitizer.embed(html), "evil.example"
  end

  test "drops an iframe served over plain http even from an allowed host" do
    html = %q{<iframe src="http://www.youtube.com/embed/abc"></iframe>}

    assert_not_includes Yulia::HtmlSanitizer.embed(html), "iframe"
  end

  test "drops a frame whose source is not a URL at all" do
    assert_not_includes Yulia::HtmlSanitizer.embed(%q{<iframe src="::::"></iframe>}), "iframe"
    assert_not_includes Yulia::HtmlSanitizer.embed(%q{<iframe></iframe>}), "iframe"
  end

  test "treats blank input as empty rather than failing" do
    assert_equal "", Yulia::HtmlSanitizer.rich_text(nil)
    assert_equal "", Yulia::HtmlSanitizer.embed("")
  end
end
