# A block a user wrote themselves, when the visual editor alone is not enough.
#
# Built-in blocks are declared in Ruby (see Yulia::BlockRegistry) and never
# reach this table: they ship with the product and nobody edits them from the
# admin panel.
#
# Two kinds exist. An "html" block is an ERB template, optionally driven by
# htmx - this is the recommended path, because it renders on the server and
# needs no JavaScript. A "svelte" block is compiled into an island and hydrated
# only on the pages that actually place it.
class BlockType < ApplicationRecord
  KINDS = %w[html svelte].freeze
  BUILD_STATUSES = %w[pending building ready failed].freeze

  # Field types the properties panel knows how to render.
  FIELD_TYPES = %w[text richtext number boolean select image link color].freeze

  belongs_to :site

  normalizes :key, with: ->(value) { value.to_s.strip.downcase }

  validates :key, presence: true, uniqueness: { scope: :site_id },
                  format: { with: /\A[a-z][a-z0-9-]*\z/,
                            message: "must start with a letter and contain only lowercase letters, digits and hyphens" }
  validates :name, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :build_status, inclusion: { in: BUILD_STATUSES }
  validate :key_does_not_shadow_builtin
  validate :schema_is_well_formed

  scope :enabled, -> { where(enabled: true) }
  scope :ready, -> { where(build_status: "ready") }

  # An HTML block is usable the moment it is saved; only Svelte needs a build.
  def usable? = enabled? && (html? || build_status == "ready")

  def html? = kind == "html"

  def svelte? = kind == "svelte"

  # Field definitions, cleaned up for the editor. A malformed entry is dropped
  # rather than allowed to break the properties panel.
  def fields
    Array(schema).filter_map do |field|
      next unless field.is_a?(Hash)

      key = field["key"].to_s
      next if key.blank?

      {
        "key" => key,
        "label" => field["label"].presence || key.humanize,
        "type" => FIELD_TYPES.include?(field["type"]) ? field["type"] : "text",
        "default" => field["default"],
        "options" => Array(field["options"])
      }
    end
  end

  def defaults
    fields.to_h { |field| [ field["key"], field["default"] ] }
  end

  private

    def key_does_not_shadow_builtin
      return if key.blank?

      if Yulia::BlockRegistry.builtin?(key)
        errors.add(:key, "is the name of a built-in block; pick another")
      end
    end

    def schema_is_well_formed
      return if schema.blank?

      unless schema.is_a?(Array)
        errors.add(:schema, "must be a list of fields")
        return
      end

      duplicates = Array(schema).filter_map { |f| f["key"] if f.is_a?(Hash) }
                               .tally.select { |_, count| count > 1 }.keys
      errors.add(:schema, "repeats field names: #{duplicates.join(', ')}") if duplicates.any?
    end
end
