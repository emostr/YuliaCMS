require "test_helper"

class TlsGateTest < ActionDispatch::IntegrationTest
  # Caddy asks this endpoint before ordering a certificate. Answering yes to
  # anything would let a stranger point a domain here and burn our Let's Encrypt
  # quota, so these tests guard the gate rather than the happy path alone.

  setup do
    @site = create_site
    @site.domains.create!(host: "claimed.example", primary: true)
  end

  test "allows a host some site has claimed" do
    get tls_allow_path, params: { domain: "claimed.example" }

    assert_response :success
  end

  test "records that a certificate was issued" do
    get tls_allow_path, params: { domain: "claimed.example" }

    assert Domain.find_by(host: "claimed.example").certified?
  end

  test "refuses a host nobody claimed" do
    get tls_allow_path, params: { domain: "stranger.example" }

    assert_response :forbidden
  end

  test "refuses a missing or empty domain" do
    get tls_allow_path
    assert_response :forbidden

    get tls_allow_path, params: { domain: "" }
    assert_response :forbidden
  end

  test "matches regardless of case and trailing dot" do
    get tls_allow_path, params: { domain: "Claimed.Example." }

    assert_response :success
  end
end
