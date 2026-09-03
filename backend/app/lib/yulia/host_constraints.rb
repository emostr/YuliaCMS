module Yulia
  # Routing constraints that split the admin panel from the sites it publishes.
  module HostConstraints
    # Matches requests for a host some site has claimed.
    class Site
      def matches?(request)
        SiteResolver.call(request.host).present?
      end
    end

    # Matches everything else: the configured admin domain, and - when none is
    # configured, which is how Yulia runs on your own machine - any host that no
    # site has claimed, so that localhost reaches the admin panel.
    class Admin
      def matches?(request)
        SiteResolver.call(request.host).blank?
      end
    end
  end
end
