class CreateFormSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :form_submissions do |t|
      t.references :site, null: false, foreign_key: true
      t.references :page, foreign_key: true

      # Which form block on the page produced this, so several forms on one
      # site stay apart.
      t.string :block_id, null: false

      t.jsonb :data, null: false, default: {}
      t.string :ip_address
      t.boolean :read, null: false, default: false

      t.datetime :created_at, null: false
    end

    add_index :form_submissions, [ :site_id, :created_at ]
  end
end
