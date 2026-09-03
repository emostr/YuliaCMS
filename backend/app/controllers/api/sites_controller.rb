module Api
  class SitesController < BaseController
    def index
      render json: { sites: accessible_sites.order(:name).map { |site| summary(site) } }
    end

    def show
      render json: { site: detail(current_site) }
    end

    def create
      site = Site.new(site_params)
      # Titles are usually Russian, and Rails' own parameterize would reduce
      # them to nothing. Yulia::Slug transliterates first.
      site.slug = Yulia::Slug.unique(site.slug.presence || site.name, fallback: "site") do |candidate|
        Site.exists?(slug: candidate)
      end

      ActiveRecord::Base.transaction do
        site.save!
        # Whoever creates a site owns it, so it appears in their list straight away.
        site.memberships.create!(user: current_user, role: "owner")
        # A site with no pages cannot be previewed, and an empty editor is a
        # poor welcome, so it starts with a home page carrying a hero.
        site.pages.create!(
          title: site.name, slug: "home", home: true, status: "draft",
          draft_content: starter_content(site)
        )
      end

      render json: { site: detail(site) }, status: :created
    end

    def update
      current_site.update!(site_params)
      render json: { site: detail(current_site) }
    end

    def destroy
      current_site.destroy!
      head :no_content
    end

    private

      def site_params
        # `navigation: []` would permit an array of scalars and silently drop
        # the menu, which is an array of {label, href}. The keys have to be
        # named for the entries to survive.
        params.expect(site: [ :name, :slug, :locale, :timezone, :theme, :accent,
                              { navigation: [ [ :label, :href ] ], settings: {} } ])
      end

      def starter_content(site)
        [
          { "id" => SecureRandom.uuid, "type" => "hero",
            "props" => Yulia::BlockRegistry.find("hero").defaults.merge("title" => site.name) }
        ]
      end

      def summary(site)
        {
          id: site.id, name: site.name, slug: site.slug,
          published: site.published, theme: site.theme, accent: site.accent,
          pages_count: site.pages.count,
          primary_domain: site.primary_domain&.host,
          url: site.public_url
        }
      end

      def detail(site)
        summary(site).merge(
          locale: site.locale, timezone: site.timezone,
          navigation: site.navigation, settings: site.settings,
          domains: site.domains.order(primary: :desc, host: :asc).map { |d|
            { id: d.id, host: d.host, primary: d.primary, certified: d.certified? }
          }
        )
      end
  end
end
