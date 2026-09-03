module Api
  # Blocks a user wrote themselves, when the visual editor is not enough.
  class BlockTypesController < BaseController
    before_action :load_block_type, only: %i[show update destroy]

    def index
      render json: { block_types: current_site.block_types.order(:name).map { |bt| serialize(bt) } }
    end

    def show
      render json: { block_type: serialize(@block_type, source: true) }
    end

    def create
      block_type = current_site.block_types.new(block_type_params)
      block_type.build_status = block_type.svelte? ? "pending" : "ready"
      block_type.save!

      CompileIslandJob.perform_later(block_type.id) if block_type.svelte?
      render json: { block_type: serialize(block_type, source: true) }, status: :created
    end

    def update
      @block_type.assign_attributes(block_type_params)
      # Editing a Svelte block invalidates whatever was built from the old source.
      @block_type.build_status = "pending" if @block_type.svelte? && @block_type.source_changed?
      @block_type.save!

      CompileIslandJob.perform_later(@block_type.id) if @block_type.svelte? && @block_type.build_status == "pending"
      render json: { block_type: serialize(@block_type, source: true) }
    end

    def destroy
      @block_type.destroy!
      head :no_content
    end

    private

      def load_block_type
        @block_type = BlockType.where(site: accessible_sites).find(params[:id])
        @current_site = @block_type.site
      end

      def block_type_params
        # The schema is a list of field definitions, so its keys are named
        # here for the same reason the site's navigation names its own.
        params.expect(block_type: [ :key, :name, :description, :icon, :kind,
                                    :template, :source, :enabled,
                                    { schema: [ [ :key, :label, :type, :default, { options: [] } ] ] } ])
      end

      def serialize(block_type, source: false)
        payload = {
          id: block_type.id, key: block_type.key, name: block_type.name,
          description: block_type.description, icon: block_type.icon,
          kind: block_type.kind, enabled: block_type.enabled,
          build_status: block_type.build_status, usable: block_type.usable?,
          fields: block_type.fields, schema: block_type.schema
        }
        return payload unless source

        payload.merge(template: block_type.template, source: block_type.source,
                      build_log: block_type.build_log)
      end
  end
end
