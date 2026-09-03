class ApplicationController < ActionController::Base
  include Authentication

  # Old browsers cannot run the admin panel, and the public sites are plain
  # server-rendered HTML that works everywhere regardless.
  allow_browser versions: :modern, if: -> { request.path.start_with?("/api") }
end
