class CreatePages < ActiveRecord::Migration[8.1]
  def change
    create_table :pages do |t|
      t.references :site, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :pages }

      t.string :title, null: false
      t.string :slug, null: false
      t.string :path, null: false

      t.string :status, null: false, default: "draft"
      t.boolean :home, null: false, default: false
      t.integer :position, null: false, default: 0

      # The editor writes to the draft; visitors are served the published copy.
      # Keeping both on the row means an unfinished edit can never leak to the
      # public site, and publishing is a single atomic column update.
      t.jsonb :draft_content, null: false, default: []
      t.jsonb :published_content
      t.datetime :published_at

      t.string :seo_title
      t.string :seo_description
      t.string :seo_image

      t.timestamps
    end

    add_index :pages, [ :site_id, :path ], unique: true
    add_index :pages, [ :site_id, :status ]
  end
end
