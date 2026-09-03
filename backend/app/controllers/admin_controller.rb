# Serves the admin panel's HTML shell.
#
# Everything the panel does happens through /api; this action only delivers the
# document that boots the Svelte application, whatever path was asked for, so
# that reloading a deep link works.
class AdminController < ApplicationController
  def index
    render html: admin_index.read.html_safe, layout: false, content_type: "text/html"
  rescue Errno::ENOENT
    render plain: build_missing_message, status: :service_unavailable
  end

  private

    def admin_index = Rails.public_path.join("admin/index.html")

    def build_missing_message
      <<~TEXT
        The admin panel has not been built.

        Run `npm install && npm run build` in admin/, or start the whole stack
        with `docker compose up -d --build`, which does it for you.
      TEXT
    end
end
