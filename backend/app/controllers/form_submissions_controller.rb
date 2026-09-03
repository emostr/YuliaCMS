# Receives what visitors type into a form block.
#
# The reply is an HTML fragment, because that is what htmx swaps in. Without
# JavaScript the same POST arrives from a plain form submit and gets a full
# page back instead, so the block works either way.
class FormSubmissionsController < ApplicationController
  # A visitor has no session and no CSRF token from us; the form is public by
  # design. Abuse is handled by rate limiting rather than by a token.
  skip_forgery_protection

  rate_limit to: 10, within: 10.minutes,
             with: -> { render_notice(t("yulia.forms.too_many"), status: :too_many_requests) }

  def create
    site = Yulia::SiteResolver.call(request.host)
    return head :not_found unless site

    block, page = find_block(site, params[:block_id])
    return head :not_found unless block

    # A hidden field no human fills in. Bots do, and their submissions are
    # accepted with a straight face and dropped.
    return render_success(block) if params[:website].present?

    submission = site.form_submissions.create!(
      page: page,
      block_id: params[:block_id],
      data: collect_values(block),
      ip_address: request.remote_ip,
      created_at: Time.current
    )

    Rails.logger.info("[yulia] form submission #{submission.id} on #{site.slug}")
    render_success(block)
  end

  private

    # Only the fields the block declares are stored: a crafted POST cannot add
    # its own keys to the record the owner will read.
    def collect_values(block)
      declared = Array(block.dig("props", "fields"))
      declared.to_h do |field|
        name = field["name"].to_s
        [ name, params[name].to_s.strip.first(5_000) ]
      end.reject { |key, _| key.blank? }
    end

    # Postgres finds the page whose published document contains this block, so
    # the lookup stays one indexed query no matter how many pages a site has.
    def find_block(site, block_id)
      needle = [ { id: block_id.to_s, type: "form" } ].to_json
      page = site.pages.published.where("published_content @> ?::jsonb", needle).first
      return [ nil, nil ] unless page

      block = page.live_content.find { |b| b["id"].to_s == block_id.to_s && b["type"] == "form" }
      [ block, page ]
    end

    def render_success(block)
      message = block.dig("props", "success_message").presence || t("yulia.forms.sent")
      render_notice(message)
    end

    def render_notice(message, status: :ok)
      html = ApplicationController.helpers.tag.div(message, class: "y-form y-form-notice")

      if request.headers["HX-Request"]
        render html: html, status: status
      else
        # No htmx: send the visitor back to the page with the notice on it.
        redirect_back fallback_location: "/", allow_other_host: false
      end
    end
end
