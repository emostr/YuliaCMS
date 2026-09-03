module Public
  # Serves the sites Yulia publishes.
  #
  # Everything here is server-rendered HTML. A page with no interactive block
  # ships no JavaScript at all; htmx is added only when something on the page
  # actually needs it, and a Svelte island's bundle only when that island is
  # placed. That is the whole point of the single rendering path.
  class PagesController < ApplicationController
    layout "public"

    skip_before_action :require_authentication, raise: false

    before_action :load_site
    before_action :load_page

    def show
      render :show
    end

    # Reached at /preview/<slug> on the admin host: how a site is opened before
    # it has a domain, and the only way to see one when running locally.
    def preview
      render :show
    end

    private

      def load_site
        @site = if action_name == "preview"
          Yulia::SiteResolver.by_slug(params[:slug])
        else
          Yulia::SiteResolver.call(request.host)
        end

        render_missing_site unless @site
      end

      def load_page
        return if performed?

        path = "/#{params[:path]}".chomp("/")
        path = "/" if path.blank?

        @page = @site.pages.find_by(path: path)

        # A draft is visible only to someone signed in to the admin panel, which
        # is what makes "preview before publishing" work without leaking the page.
        @page = nil if @page && !@page.published? && !preview_allowed?

        return render_not_found unless @page

        @blocks = preview_allowed? && !@page.published? ? @page.draft_blocks : @page.live_content
        @renderer = Yulia::BlockRenderer.new(site: @site, page: @page, request: request)
        @islands = @renderer.islands_for(@blocks)
      end

      def preview_allowed?
        signed_in? && current_user.second_factor_enrolled?
      end

      def render_missing_site
        render "public/pages/no_site", layout: "public_bare", status: :not_found
      end

      def render_not_found
        render "public/pages/not_found", status: :not_found
      end
  end
end
