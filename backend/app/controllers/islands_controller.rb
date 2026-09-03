# Serves compiled Svelte islands.
#
# They are not in public/ because that directory ships inside the image and is
# replaced on every update, while islands are written after installation and
# must survive it. They live on the storage volume instead, and this action
# hands them out.
class IslandsController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  ROOT = Rails.root.join("storage/islands")

  def show
    site_id = params[:site_id].to_s
    key = params[:key].to_s

    # Both segments come from a URL. Rejecting anything but the expected shape
    # is what keeps "../../config/master.key" from being a valid island name.
    return head :not_found unless site_id.match?(/\A\d+\z/) && key.match?(/\A[a-z][a-z0-9-]*\z/)

    path = ROOT.join(site_id, "#{key}.js")
    return head :not_found unless path.exist?

    # A block's bundle changes only when its author edits it, and the etag
    # follows the file, so browsers can hold on to it.
    expires_in 1.hour, public: true
    send_file path, type: "text/javascript", disposition: "inline"
  end
end
