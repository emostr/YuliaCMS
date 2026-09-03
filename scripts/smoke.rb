#!/usr/bin/env ruby
# frozen_string_literal: true

# Walks the whole product against a running stack.
#
# Unit tests run against the application in isolation, with forgery protection
# off and no proxy in front. This walks the path a real person takes, through
# Caddy, against the production image: create the owner, enrol a second factor,
# build a site, publish a page, attach a domain, read the site as a visitor and
# send its form. Bugs live in exactly that gap - a page that could not be saved
# in production passed every unit test.
#
# Expects a stack with an empty database:
#
#   docker compose down && docker volume rm project-yulia_pgdata project-yulia_storage
#   docker compose up -d
#   cd backend && bundle exec ruby ../scripts/smoke.rb
#
require "net/http"
require "json"
require "uri"
require "rotp"

BASE = ENV.fetch("YULIA_URL", "http://localhost:8080")
$cookies = {}
$csrf = nil
$failures = []

def check(name, condition, detail = nil)
  if condition
    puts "  ok    #{name}"
  else
    puts "  FAIL  #{name}#{detail ? " — #{detail}" : ''}"
    $failures << name
  end
end

def request(method, path, body = nil, host: nil)
  uri = URI("#{BASE}#{path}")
  klass = { get: Net::HTTP::Get, post: Net::HTTP::Post,
            patch: Net::HTTP::Patch, delete: Net::HTTP::Delete }.fetch(method)
  req = klass.new(uri)
  req["Accept"] = "application/json"
  req["Host"] = host if host
  req["Cookie"] = $cookies.map { |k, v| "#{k}=#{v}" }.join("; ") unless $cookies.empty?
  if body
    req["Content-Type"] = "application/json"
    req["X-CSRF-Token"] = $csrf if $csrf
    req.body = body.to_json
  end

  res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }

  Array(res.get_fields("set-cookie")).each do |cookie|
    name, value = cookie.split(";").first.split("=", 2)
    $cookies[name] = value
  end

  parsed = begin
    JSON.parse(res.body)
  rescue StandardError
    res.body
  end
  [res.code.to_i, parsed]
end

puts "\n1. Setup is offered on a fresh installation"
code, body = request(:get, "/api/setup")
check("setup endpoint answers", code == 200)
check("installation needs setup", body["needs_setup"] == true, body.inspect)

# The CSRF token has to be picked up before anything is written, exactly as the
# admin panel does on load.
_, session = request(:get, "/api/session")
$csrf = session["csrf_token"]
check("csrf token issued", !$csrf.to_s.empty?)

puts "\n2. Creating the owner"
password = "correct horse battery staple"
code, body = request(:post, "/api/setup", {
  setup: { email: "owner@example.com", name: "Владелец",
           password: password, password_confirmation: password }
})
check("owner created", code == 201, body.inspect)
check("told to enrol a second factor", body["next"] == "enrol_second_factor")

_, session = request(:get, "/api/session")
$csrf = session["csrf_token"]

puts "\n3. Nothing is reachable before the second factor"
code, body = request(:get, "/api/sites")
check("admin API refuses", code == 403, "got #{code}")
check("and says why", body["error"] == "second_factor_required")

puts "\n4. Enrolling TOTP"
code, body = request(:post, "/api/second_factor/totp", {})
check("secret issued", code == 200 && !body["secret"].to_s.empty?, body.inspect)
check("qr code rendered on the server", body["qr_svg"].to_s.include?("<svg"))
secret = body["secret"]

code, body = request(:post, "/api/second_factor/confirm_totp", { code: "000000" })
check("a wrong code is refused", code == 422)

code, body = request(:post, "/api/second_factor/confirm_totp", { code: ROTP::TOTP.new(secret).now })
check("a real code is accepted", code == 200, body.inspect)
check("recovery codes handed over once", body["recovery_codes"].is_a?(Array) && body["recovery_codes"].size == 10)

puts "\n5. Building a site"
code, body = request(:get, "/api/sites")
check("admin API now open", code == 200, body.inspect)

code, body = request(:post, "/api/sites", { site: { name: "Кофейня «Пар»" } })
check("site created", code == 201, body.inspect)
site_id = body.dig("site", "id")
slug = body.dig("site", "slug")
check("site starts with a page", body.dig("site", "pages_count") == 1)

code, body = request(:get, "/api/sites/#{site_id}/pages")
home = body["pages"].first
check("home page exists", !home.nil? && home["home"] == true)

code, body = request(:get, "/api/sites/#{site_id}/blocks")
check("block palette served", body["builtin"].is_a?(Array) && body["builtin"].size >= 13,
      "got #{body['builtin']&.size} builtin blocks")

puts "\n6. Editing and publishing"
blocks = [
  { "id" => "h1", "type" => "hero",
    "props" => { "title" => "Кофейня «Пар»", "subtitle" => "Обжариваем сами",
                 "button_label" => "Меню", "button_href" => "/", "align" => "center" } },
  { "id" => "t1", "type" => "text",
    "props" => { "html" => "<p>Открыты с <strong>2014</strong>.</p><script>alert(1)</script>",
                 "width" => "normal" } },
  { "id" => "f1", "type" => "form",
    "props" => { "title" => "Напишите нам", "submit_label" => "Отправить",
                 "success_message" => "Спасибо!",
                 "fields" => [ { "label" => "Имя", "name" => "name", "type" => "text", "required" => true } ] } }
]

code, body = request(:patch, "/api/pages/#{home['id']}", { page: { draft_content: blocks } })
check("draft saved", code == 200, body.inspect)
check("publishing would change something", body.dig("page", "has_unpublished_changes") == true)

code, body = request(:post, "/api/pages/#{home['id']}/publish", {})
check("page published", code == 200 && body.dig("page", "status") == "published", body.inspect)
check("nothing left unpublished", body.dig("page", "has_unpublished_changes") == false)

puts "\n7. Attaching a domain"
code, body = request(:post, "/api/sites/#{site_id}/domains", { domain: { host: "par.example" } })
check("domain added", code == 201, body.inspect)
check("first domain becomes primary", body.dig("domain", "primary") == true)
check("dns was checked and reported", body.dig("domain", "dns").is_a?(Hash))

puts "\n8. Reading the site as a visitor"
uri = URI("#{BASE}/")
req = Net::HTTP::Get.new(uri)
req["Host"] = "par.example"
res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
html = res.body.dup.force_encoding("UTF-8")

check("site answers on its own host", res.code.to_i == 200, "got #{res.code}")
check("hero rendered", html.include?("Обжариваем сами"))
check("rich text kept its formatting", html.include?("<strong>2014</strong>"))
check("script from the editor was stripped", !html.include?("alert(1)"))
check("htmx loaded because the page has a form", html.include?("/yulia/htmx.min.js"))
check("stylesheet linked", html.include?("/yulia/site.css"))
check("canonical points at the domain", html.include?('href="https://par.example/"'))

puts "\n9. TLS gate"
code, = request(:get, "/_yulia/tls/allow?domain=par.example")
check("known domain allowed", code == 200)
code, = request(:get, "/_yulia/tls/allow?domain=stranger.example")
check("unknown domain refused", code == 403)

puts "\n10. A visitor sends the form"
uri = URI("#{BASE}/_yulia/forms/f1")
req = Net::HTTP::Post.new(uri)
req["Host"] = "par.example"
req["HX-Request"] = "true"
req.set_form_data("name" => "Иван")
res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
check("submission accepted", res.code.to_i == 200, "got #{res.code}")
reply = res.body.dup.force_encoding("UTF-8")
check("htmx gets a fragment back", reply.include?("Спасибо!"), reply[0, 120])

code, body = request(:get, "/api/sites/#{site_id}/form_submissions")
check("submission visible in the admin", body["submissions"]&.first&.dig("fields", "name") == "Иван",
      body.inspect[0, 200])

puts "\n" + ("-" * 60)
if $failures.empty?
  puts "END TO END: everything passed"
else
  puts "END TO END: #{$failures.size} failed"
  $failures.each { |f| puts "  - #{f}" }
  exit 1
end
