require "test_helper"

class FormSubmissionTest < ActionDispatch::IntegrationTest
  setup do
    @site = create_site(slug: "coffee")
    @site.domains.create!(host: "coffee.example", primary: true)

    @page = create_page(site: @site, content: [
      block(:form, id: "contact", title: "Напишите",
            success_message: "Спасибо!",
            fields: [
              { "label" => "Имя", "name" => "name", "type" => "text", "required" => true },
              { "label" => "Почта", "name" => "email", "type" => "email", "required" => true }
            ])
    ])
    @page.publish!
  end

  test "stores a submission and answers with a fragment htmx can swap in" do
    assert_difference -> { FormSubmission.count }, 1 do
      post "/_yulia/forms/contact",
           params: { name: "Иван", email: "ivan@example.com" },
           headers: { "HOST" => "coffee.example", "HX-Request" => "true" }
    end

    assert_response :success
    assert_includes response.body, "Спасибо!"

    submission = FormSubmission.last
    assert_equal({ "name" => "Иван", "email" => "ivan@example.com" }, submission.fields)
    assert_equal @page, submission.page
  end

  test "keeps only the fields the block declares" do
    post "/_yulia/forms/contact",
         params: { name: "Иван", email: "i@example.com", role: "admin", is_admin: "true" },
         headers: { "HOST" => "coffee.example", "HX-Request" => "true" }

    assert_equal %w[name email].sort, FormSubmission.last.fields.keys.sort,
                 "a crafted POST must not add keys to the record the owner reads"
  end

  test "accepts a bot's submission without storing it" do
    assert_no_difference -> { FormSubmission.count } do
      post "/_yulia/forms/contact",
           params: { name: "Bot", email: "b@b.co", website: "http://spam" },
           headers: { "HOST" => "coffee.example", "HX-Request" => "true" }
    end

    assert_response :success
  end

  test "refuses a block that is not on any published page" do
    post "/_yulia/forms/made-up",
         params: { name: "X" },
         headers: { "HOST" => "coffee.example", "HX-Request" => "true" }

    assert_response :not_found
  end

  test "refuses a host that belongs to no site" do
    post "/_yulia/forms/contact",
         params: { name: "X" },
         headers: { "HOST" => "stranger.example", "HX-Request" => "true" }

    assert_response :not_found
  end

  test "truncates an oversized value rather than storing it whole" do
    post "/_yulia/forms/contact",
         params: { name: "a" * 10_000, email: "i@example.com" },
         headers: { "HOST" => "coffee.example", "HX-Request" => "true" }

    assert_operator FormSubmission.last.fields["name"].length, :<=, 5_000
  end
end
