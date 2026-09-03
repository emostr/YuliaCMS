module Yulia
  # Turns one block of a page's JSON document into HTML.
  #
  # Templates - built-in and user-written alike - are Liquid. Liquid does not
  # evaluate Ruby, so a template typed into the admin panel cannot reach the
  # server it runs on. That is the whole reason this is not ERB.
  class BlockRenderer
    # A runaway template must not be able to hold a request open. These caps
    # abort rendering rather than let one page starve the site.
    #
    # Liquid reads its limits from an Environment, so Yulia keeps one of its
    # own instead of reconfiguring the library globally for the whole process.
    ENVIRONMENT = Liquid::Environment.build(error_mode: :lax) do |env|
      env.default_resource_limits = {
        render_length_limit: 500_000,
        render_score_limit: 200_000,
        assign_score_limit: 100_000
      }
    end

    def initialize(site:, page: nil, request: nil)
      @site = site
      @page = page
      @request = request
      @custom_types = site.block_types.enabled.index_by(&:key)
    end

    # Returns the rendered HTML. A block that cannot be rendered yields a quiet
    # placeholder instead of taking the whole page down with it: one broken
    # block should not cost a visitor the other twenty.
    def render(block)
      type = block["type"].to_s
      props = block["props"].is_a?(Hash) ? block["props"] : {}

      definition = BlockRegistry.find(type)
      return render_builtin(definition, block, props) if definition

      custom = @custom_types[type]
      return placeholder("unknown block: #{type}") unless custom&.usable?

      custom.svelte? ? render_island(custom, block, props) : render_custom(custom, block, props)
    end

    # Which Svelte islands a page needs, so the layout can load exactly those
    # bundles and nothing else.
    def islands_for(blocks)
      blocks.filter_map do |block|
        custom = @custom_types[block["type"].to_s]
        custom if custom&.svelte? && custom.usable?
      end.uniq
    end

    private

      def render_builtin(definition, block, props)
        assigns = base_assigns(block, prepare_props(definition.fields, props))
        run(definition.template, assigns, label: "block #{definition.key}")
      end

      def render_custom(custom, block, props)
        fields = custom.fields.map { |f| { key: f["key"], type: f["type"] } }
        assigns = base_assigns(block, prepare_props(fields, props))
        run(custom.template, assigns, label: "custom block #{custom.key}")
      end

      # A Svelte block renders as an empty mount point. The island's own bundle
      # fills it in the browser; the props travel in a data attribute so that
      # the server stays the only source of the block's content.
      def render_island(custom, block, props)
        payload = prepare_props(custom.fields.map { |f| { key: f["key"], type: f["type"] } }, props)

        helpers.tag.div(
          "",
          class: "y-island",
          data: {
            yulia_island: custom.key,
            yulia_props: payload.to_json
          }
        ).to_s
      end

      def base_assigns(block, props)
        {
          "block" => props.merge("id" => block["id"].to_s, "type" => block["type"].to_s),
          "site" => {
            "name" => @site.name,
            "locale" => @site.locale,
            "url" => @site.public_url
          },
          "page" => {
            "title" => @page&.title.to_s,
            "path" => @page&.path.to_s
          },
          "form" => {
            "action" => "/_yulia/forms/#{block['id']}",
            "csrf_token" => @request ? form_authenticity_token : ""
          }
        }
      end

      # Runs every value through the treatment its declared type calls for.
      # Anything typed as markup is sanitised here, once, rather than being
      # trusted because it "came from the editor".
      def prepare_props(fields, props)
        types = fields.to_h { |f| [ f[:key].to_s, f[:type].to_s ] }

        props.to_h do |key, value|
          [ key.to_s, coerce(types[key.to_s], value) ]
        end
      end

      def coerce(type, value)
        case type
        when "richtext" then HtmlSanitizer.rich_text(value)
        when "code"     then HtmlSanitizer.embed(value)
        when "boolean"  then ActiveModel::Type::Boolean.new.cast(value)
        when "list"     then Array(value).map { |item| item.is_a?(Hash) ? item.transform_keys(&:to_s) : item }
        else value
        end
      end

      def run(source, assigns, label:)
        template = Liquid::Template.parse(source, environment: ENVIRONMENT)
        html = template.render(assigns, strict_variables: false)

        if template.errors.any?
          Rails.logger.warn("[yulia] #{label}: #{template.errors.map(&:message).join('; ')}")
        end

        html.html_safe
      rescue Liquid::Error, StandardError => e
        Rails.logger.error(
          "[yulia] #{label} failed to render: #{e.class}: #{e.message}\n" \
          "#{e.backtrace&.first(3)&.join("\n")}"
        )
        placeholder("#{label} could not be rendered")
      end

      def placeholder(message)
        # Visible to whoever is editing, invisible to a visitor: a broken block
        # should tell its author something without defacing the live page.
        helpers.tag.div(message, class: "y-block-error", hidden: true).to_s.html_safe
      end

      def helpers = ActionController::Base.helpers

      def form_authenticity_token
        @request.env["action_controller.instance"]&.send(:form_authenticity_token).to_s
      rescue StandardError
        ""
      end
  end
end
