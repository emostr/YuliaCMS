module Api
  class PagesController < BaseController
    before_action :load_page, only: %i[show update destroy publish unpublish restore]

    def index
      render json: { pages: current_site.pages.ordered.map { |page| summary(page) } }
    end

    def show
      render json: { page: detail(@page) }
    end

    def create
      page = current_site.pages.new(page_params)
      page.slug = Yulia::Slug.unique(page.slug.presence || page.title) do |candidate|
        current_site.pages.exists?(slug: candidate)
      end
      page.save!
      render json: { page: detail(page) }, status: :created
    end

    def update
      # Content is handled apart from the page's own fields for two reasons:
      # saving the draft snapshots the previous version and renaming the page
      # must not, and the block document has a shape strong parameters cannot
      # describe - see Yulia::BlockDocument.
      if params[:page].key?(:draft_content)
        blocks = Yulia::BlockDocument.sanitize(params[:page][:draft_content])
        @page.save_draft!(blocks, user: current_user)
      end

      attributes = page_params
      @page.update!(attributes) if attributes.present?

      render json: { page: detail(@page) }
    end

    def destroy
      @page.destroy!
      head :no_content
    end

    def publish
      @page.publish!(user: current_user)
      render json: { page: detail(@page) }
    end

    def unpublish
      @page.unpublish!
      render json: { page: detail(@page) }
    end

    # Pulls the live version back into the editor, abandoning the draft.
    def restore
      @page.restore_published_into_draft!
      render json: { page: detail(@page) }
    end

    private

      def load_page
        @page = if params[:site_id]
          current_site.pages.find(params[:id])
        else
          Page.where(site: accessible_sites).find(params[:id])
        end
        @current_site = @page.site
      end

      def page_params
        return {} unless params[:page].is_a?(ActionController::Parameters)

        params[:page].permit(:title, :slug, :status, :home, :position,
                             :seo_title, :seo_description, :seo_image)
      end

      def summary(page)
        {
          id: page.id, title: page.title, slug: page.slug, path: page.path,
          status: page.status, home: page.home, position: page.position,
          published_at: page.published_at, updated_at: page.updated_at,
          # Tells the editor whether "publish" would actually change anything.
          has_unpublished_changes: page.draft_blocks != page.live_content
        }
      end

      def detail(page)
        summary(page).merge(
          site_id: page.site_id,
          draft_content: page.draft_blocks,
          seo_title: page.seo_title,
          seo_description: page.seo_description,
          seo_image: page.seo_image
        )
      end
  end
end
