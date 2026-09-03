module Api
  class DomainsController < BaseController
    def index
      render json: { domains: current_site.domains.order(primary: :desc, host: :asc).map { |d| serialize(d) } }
    end

    def create
      # Whether this is the site's first domain - and so its canonical one - is
      # decided by the model, which can ask the database rather than the
      # half-built association.
      domain = current_site.domains.new(host: params.dig(:domain, :host))
      domain.save!

      render json: { domain: serialize(domain, check: true) }, status: :created
    end

    def primary
      domain = Domain.where(site: accessible_sites).find(params[:id])
      domain.make_primary!
      render json: { domain: serialize(domain) }
    end

    def destroy
      domain = Domain.where(site: accessible_sites).find(params[:id])
      domain.destroy!
      head :no_content
    end

    private

      def serialize(domain, check: false)
        payload = {
          id: domain.id, host: domain.host, primary: domain.primary,
          certified: domain.certified?, certified_at: domain.certified_at
        }
        return payload unless check

        # Checking DNS costs a network round trip, so it happens when a domain
        # is added rather than every time the list is drawn.
        result = Yulia::DnsChecker.check(domain.host)
        domain.update(dns_checked_at: Time.current,
                      last_error: result.ok? ? nil : result.error.to_s)

        payload.merge(dns: {
          ok: result.ok?, addresses: result.addresses,
          expected: result.expected, error: result.error
        })
      end
  end
end
