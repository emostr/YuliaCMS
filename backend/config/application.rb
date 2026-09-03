require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Yulia
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # The admin panel and the sites it publishes are aimed at Russian-speaking
    # users, so Russian is the default; English is available as a fallback.
    config.i18n.default_locale = :ru
    config.i18n.available_locales = %i[ru en]
    config.i18n.fallbacks = [ :en ]

    # Rails refuses hosts it was not told about, which protects an application
    # that builds URLs out of the Host header. Yulia cannot use that list: its
    # whole job is serving domains its users add later, without redeploying.
    #
    # The gate is Yulia::SiteResolver instead. A host is served only when some
    # site has claimed it; anything else reaches the admin panel or a 404, and
    # Caddy will not obtain a certificate for a name absent from the domains
    # table (see TlsController).
    config.hosts.clear

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end
