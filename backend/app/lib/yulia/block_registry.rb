module Yulia
  # The blocks that ship with Yulia.
  #
  # A definition is a schema plus a Liquid template. Built-in blocks use the
  # very same template language as blocks a user writes in the admin panel, so
  # the files in app/blocks double as worked examples: "how do I build my own
  # gallery?" is answered by reading gallery.liquid.
  module BlockRegistry
    Definition = Struct.new(:key, :icon, :category, :fields, :template, keyword_init: true) do
      def builtin? = true

      # Values the editor starts a freshly inserted block with.
      def defaults
        fields.to_h { |field| [ field[:key].to_s, field[:default] ] }
      end

      def field(key) = fields.find { |f| f[:key].to_s == key.to_s }
    end

    TEMPLATE_DIR = Rails.root.join("app/blocks")

    # Categories group the block picker into sections.
    CATEGORIES = %w[text media layout interactive].freeze

    # Schemas are declared here; the markup lives beside them in app/blocks.
    SCHEMAS = {
      "heading" => {
        icon: "heading", category: "text",
        fields: [
          { key: :text, type: "text", default: "Заголовок" },
          { key: :level, type: "select", default: "2", options: %w[1 2 3 4] },
          { key: :align, type: "select", default: "left", options: %w[left center right] }
        ]
      },
      "text" => {
        icon: "text", category: "text",
        fields: [
          { key: :html, type: "richtext", default: "<p>Расскажите о себе.</p>" },
          { key: :width, type: "select", default: "normal", options: %w[narrow normal wide] }
        ]
      },
      "quote" => {
        icon: "quote", category: "text",
        fields: [
          { key: :text, type: "textarea", default: "Цитата, которая стоит того, чтобы её прочли." },
          { key: :author, type: "text", default: "" },
          { key: :role, type: "text", default: "" }
        ]
      },
      "image" => {
        icon: "image", category: "media",
        fields: [
          { key: :src, type: "image", default: "" },
          { key: :alt, type: "text", default: "" },
          { key: :caption, type: "text", default: "" },
          { key: :width, type: "select", default: "normal", options: %w[narrow normal wide full] }
        ]
      },
      "gallery" => {
        icon: "gallery", category: "media",
        fields: [
          { key: :images, type: "list", default: [],
            item_fields: [
              { key: :src, type: "image", default: "" },
              { key: :alt, type: "text", default: "" }
            ] },
          { key: :columns, type: "select", default: "3", options: %w[2 3 4] }
        ]
      },
      "button" => {
        icon: "button", category: "interactive",
        fields: [
          { key: :label, type: "text", default: "Подробнее" },
          { key: :href, type: "link", default: "/" },
          { key: :variant, type: "select", default: "solid", options: %w[solid outline ghost] },
          { key: :align, type: "select", default: "left", options: %w[left center right] }
        ]
      },
      "hero" => {
        icon: "hero", category: "layout",
        fields: [
          { key: :eyebrow, type: "text", default: "" },
          { key: :title, type: "text", default: "Название вашего сайта" },
          { key: :subtitle, type: "textarea", default: "Одна строка о том, чем вы занимаетесь." },
          { key: :image, type: "image", default: "" },
          { key: :button_label, type: "text", default: "" },
          { key: :button_href, type: "link", default: "" },
          { key: :align, type: "select", default: "center", options: %w[left center] }
        ]
      },
      "features" => {
        icon: "grid", category: "layout",
        fields: [
          { key: :title, type: "text", default: "" },
          { key: :items, type: "list", default: [],
            item_fields: [
              { key: :title, type: "text", default: "" },
              { key: :text, type: "textarea", default: "" }
            ] },
          { key: :columns, type: "select", default: "3", options: %w[2 3 4] }
        ]
      },
      "cta" => {
        icon: "megaphone", category: "layout",
        fields: [
          { key: :title, type: "text", default: "Готовы начать?" },
          { key: :text, type: "textarea", default: "" },
          { key: :button_label, type: "text", default: "Написать нам" },
          { key: :button_href, type: "link", default: "" }
        ]
      },
      "divider" => {
        icon: "minus", category: "layout",
        fields: [
          { key: :style, type: "select", default: "line", options: %w[line dots space] }
        ]
      },
      "spacer" => {
        icon: "space", category: "layout",
        fields: [
          { key: :size, type: "select", default: "medium", options: %w[small medium large] }
        ]
      },
      # The showcase for htmx: the form posts itself and swaps in the reply
      # without a page reload, and without a line of JavaScript from the user.
      "form" => {
        icon: "form", category: "interactive",
        fields: [
          { key: :title, type: "text", default: "Напишите нам" },
          { key: :fields, type: "list",
            default: [
              { "label" => "Имя", "name" => "name", "type" => "text", "required" => true },
              { "label" => "Почта", "name" => "email", "type" => "email", "required" => true },
              { "label" => "Сообщение", "name" => "message", "type" => "textarea", "required" => true }
            ],
            item_fields: [
              { key: :label, type: "text", default: "" },
              { key: :name, type: "text", default: "" },
              { key: :type, type: "select", default: "text", options: %w[text email tel textarea] },
              { key: :required, type: "boolean", default: false }
            ] },
          { key: :submit_label, type: "text", default: "Отправить" },
          { key: :success_message, type: "text", default: "Спасибо! Мы получили ваше сообщение." }
        ]
      },
      "embed" => {
        icon: "code", category: "interactive",
        fields: [
          { key: :html, type: "code", default: "" },
          { key: :caption, type: "text", default: "" }
        ]
      }
    }.freeze

    class << self
      def all
        @all ||= SCHEMAS.map do |key, schema|
          Definition.new(
            key: key,
            icon: schema[:icon],
            category: schema[:category],
            fields: schema[:fields],
            template: read_template(key)
          )
        end.index_by(&:key).freeze
      end

      def find(key) = all[key.to_s]

      def builtin?(key) = SCHEMAS.key?(key.to_s)

      def keys = SCHEMAS.keys

      private

        def read_template(key)
          path = TEMPLATE_DIR.join("#{key}.liquid")
          raise "missing template for built-in block #{key.inspect} at #{path}" unless path.exist?

          path.read
        end
    end
  end
end
