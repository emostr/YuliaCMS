module Api
  # What visitors sent through form blocks, shown back to the site's owner.
  class FormSubmissionsController < BaseController
    def index
      submissions = current_site.form_submissions.includes(:page).recent.limit(200)

      render json: {
        submissions: submissions.map { |submission|
          {
            id: submission.id,
            fields: submission.fields,
            page_title: submission.page&.title,
            created_at: submission.created_at,
            read: submission.read
          }
        }
      }
    end

    def destroy
      submission = FormSubmission.where(site: accessible_sites).find(params[:id])
      submission.destroy!
      head :no_content
    end
  end
end
