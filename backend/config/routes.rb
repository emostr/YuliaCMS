Rails.application.routes.draw do
  # Container orchestration and the installer both poll this.
  get "up" => "rails/health#show", as: :rails_health_check

  # --- Machine endpoints -------------------------------------------------------
  #
  # Reached on every host, because Caddy asks about certificates before it knows
  # which site the name belongs to.

  # Compiled Svelte islands, served from the storage volume rather than public/.
  get "/yulia/islands/:site_id/:key", to: "islands#show", constraints: { key: /[a-z][a-z0-9-]*/ }, defaults: { format: "js" }

  scope "/_yulia" do
    get "tls/allow", to: "tls#allow"
    post "forms/:block_id", to: "form_submissions#create", as: :form_submission
  end

  # --- Public sites ------------------------------------------------------------

  constraints Yulia::HostConstraints::Site.new do
    root to: "public/pages#show", as: :site_root
    get "/*path", to: "public/pages#show", as: :site_page, format: false
  end

  # --- Admin panel -------------------------------------------------------------

  constraints Yulia::HostConstraints::Admin.new do
    namespace :api do
      # Whether the installation has an owner yet, and how to create one.
      resource :setup, only: [ :show, :create ]

      # Sign-in is deliberately several steps: password, then second factor.
      resource :session, only: [ :show, :create, :destroy ] do
        post :second_factor
      end

      resource :second_factor, only: [ :show ] do
        post :totp
        post :confirm_totp
        post :recovery_codes
      end

      resources :sites do
        resources :pages, shallow: true do
          member do
            post :publish
            post :unpublish
            post :restore
          end
          resources :revisions, only: [ :index ], module: :pages
        end

        resources :domains, shallow: true, only: [ :index, :create, :destroy ] do
          member { post :primary }
        end

        resources :block_types, shallow: true
        resources :media_items, shallow: true, only: [ :index, :create, :destroy ]
      resources :form_submissions, shallow: true, only: [ :index, :destroy ]
      end

      # The palette the block picker shows: built-ins plus this site's own.
      get "sites/:site_id/blocks", to: "blocks#index", as: :site_blocks
    end

    # Previewing a site that has no domain yet - the usual case right after
    # creating one, and the only way to see a site when running locally.
    get "/preview/:slug", to: "public/pages#preview", as: :preview_root
    get "/preview/:slug/*path", to: "public/pages#preview", as: :preview_page, format: false

    # Everything else is the single-page admin application; the client-side
    # router decides what to show.
    root to: "admin#index"
    get "/*path", to: "admin#index", format: false,
        constraints: ->(request) { request.format.html? }
  end
end
