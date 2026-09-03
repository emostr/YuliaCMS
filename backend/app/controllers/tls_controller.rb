# Caddy asks here before ordering a certificate for a name it does not know.
#
# Answering "yes" to everything would let anyone point a domain at this server
# and spend our Let's Encrypt quota, so the answer is yes only for hostnames
# some site has actually claimed in the admin panel.
class TlsController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def allow
    host = Yulia::SiteResolver.normalize(params[:domain])

    if host.present? && (host == Yulia.admin_domain || Domain.exists?(host: host))
      Domain.where(host: host).update_all(certified_at: Time.current)
      head :ok
    else
      # Caddy reads any non-2xx as a refusal.
      head :forbidden
    end
  end
end
