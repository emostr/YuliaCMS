module Api
  module Pages
    # The editor's undo history, kept server-side so it survives a closed tab.
    class RevisionsController < BaseController
      def index
        page = Page.where(site: accessible_sites).find(params[:page_id])

        render json: {
          revisions: page.revisions.recent.limit(50).map { |revision|
            {
              id: revision.id,
              label: revision.label,
              created_at: revision.created_at,
              author: revision.user&.name.presence || revision.user&.email,
              blocks: revision.content.size
            }
          }
        }
      end
    end
  end
end
