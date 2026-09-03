module Api
  # The palette the editor's block picker shows: everything that ships with
  # Yulia, plus whatever this site's owner has written.
  class BlocksController < BaseController
    def index
      render json: {
        builtin: Yulia::BlockRegistry.all.values.map { |definition| serialize_builtin(definition) },
        custom: current_site.block_types.enabled.order(:name).map { |bt| serialize_custom(bt) },
        categories: Yulia::BlockRegistry::CATEGORIES
      }
    end

    private

      def serialize_builtin(definition)
        {
          key: definition.key, icon: definition.icon, category: definition.category,
          builtin: true, usable: true,
          fields: definition.fields.map { |field| field.transform_keys(&:to_s) },
          defaults: definition.defaults
        }
      end

      def serialize_custom(block_type)
        {
          key: block_type.key, name: block_type.name, icon: block_type.icon,
          category: "custom", builtin: false, kind: block_type.kind,
          usable: block_type.usable?, build_status: block_type.build_status,
          description: block_type.description,
          fields: block_type.fields, defaults: block_type.defaults
        }
      end
  end
end
