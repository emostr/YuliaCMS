module Api
  # Shared behaviour for the admin API the Svelte panel talks to.
  class BaseController < ApplicationController
    before_action :require_authentication

    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_invalid

    private

      # Sites are only reachable through a membership, so one editor cannot
      # read or edit another customer's site by guessing an id.
      def current_site
        @current_site ||= accessible_sites.find(params[:site_id] || params[:id])
      end

      def accessible_sites
        current_user.owner? ? Site.all : current_user.sites
      end

      def render_not_found(error = nil)
        render json: { error: "not_found" }, status: :not_found
      end

      def render_invalid(error)
        render json: {
          error: "invalid",
          messages: error.record.errors.full_messages,
          fields: error.record.errors.to_hash(true)
        }, status: :unprocessable_content
      end
  end
end
