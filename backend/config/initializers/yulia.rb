# Settings the rest of the application reads, resolved once from the
# environment. Everything a person configures at install time arrives as an
# environment variable, so this is the single place that knows their names.
module Yulia
  # Raised when a passkey's signature counter fails to advance, which is how
  # WebAuthn reports that a credential may have been cloned.
  class ClonedCredentialError < StandardError; end

  # Raised when a request arrives for a host no site claims.
  class UnknownHostError < StandardError; end

  class << self
    def admin_domain = ENV["ADMIN_DOMAIN"].presence

    # Address of the admin panel. Without a domain - the usual case when
    # running on your own machine - it is reached over plain HTTP on the port
    # docker compose publishes.
    def admin_url
      return "https://#{admin_domain}" if admin_domain

      "http://localhost:#{ENV.fetch('HTTP_PORT', 8080)}"
    end

    def session_days = ENV.fetch("SESSION_DAYS", 30).to_i

    def max_upload_mb = ENV.fetch("MAX_UPLOAD_MB", 64).to_i

    def max_upload_bytes = max_upload_mb.megabytes

    # True when the request's host is the admin panel rather than a site.
    # With no admin domain configured, any host that is not claimed by a site
    # falls through to the admin, which is what makes localhost work.
    def admin_host?(host)
      return true if admin_domain.blank? && Domain.where(host: host.to_s.downcase).none?

      admin_domain.present? && host.to_s.downcase == admin_domain
    end
  end
end
