class CreateBlockTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :block_types do |t|
      # Custom blocks belong to a site. Built-in blocks are declared in Ruby
      # and never reach this table.
      t.references :site, null: false, foreign_key: true

      t.string :key, null: false
      t.string :name, null: false
      t.string :description, null: false, default: ""
      t.string :icon, null: false, default: "puzzle"

      # "html"   - an ERB template, optionally driven by htmx (the recommended path)
      # "svelte" - a component compiled into an island and hydrated on the page
      t.string :kind, null: false, default: "html"

      # Field definitions the editor renders in the block's properties panel.
      t.jsonb :schema, null: false, default: []

      t.text :template, null: false, default: ""
      t.text :source, null: false, default: ""

      # Build output for Svelte islands, produced by a background job.
      t.string :build_status, null: false, default: "pending"
      t.text :build_log, null: false, default: ""
      t.string :asset_path

      t.boolean :enabled, null: false, default: true
      t.timestamps
    end

    add_index :block_types, [ :site_id, :key ], unique: true
  end
end
