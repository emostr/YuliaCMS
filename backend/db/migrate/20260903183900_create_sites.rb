class CreateSites < ActiveRecord::Migration[8.1]
  def change
    create_table :sites do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :locale, null: false, default: "ru"
      t.string :timezone, null: false, default: "Europe/Moscow"

      # Site appearance, drawn from the NightingaleUI palette.
      t.string :theme, null: false, default: "light"
      t.string :accent, null: false, default: "teal"

      t.boolean :published, null: false, default: false
      t.datetime :published_at

      # Menus, footer and analytics snippets: everything that does not warrant
      # a table of its own.
      t.jsonb :navigation, null: false, default: []
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end

    add_index :sites, :slug, unique: true
  end
end
