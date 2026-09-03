module Yulia
  # Works out which site a request belongs to.
  #
  # One installation serves many sites plus the admin panel, all on the same
  # port, so the Host header is the only thing that tells them apart.
  module SiteResolver
    class << self
      # Returns the site serving this host, or nil when the host belongs to the
      # admin panel or to nobody.
      def call(host)
        normalized = normalize(host)
        return nil if normalized.blank?
        return nil if normalized == Yulia.admin_domain

        Domain.includes(:site).find_by(host: normalized)&.site
      end

      # Running locally there are no real domains, so a site can also be reached
      # at /preview/<slug> on the admin host. This resolves that form.
      def by_slug(slug) = Site.find_by(slug: slug.to_s.downcase)

      def normalize(host)
        host.to_s.split(":").first.to_s.strip.downcase.delete_suffix(".")
      end
    end
  end
end
