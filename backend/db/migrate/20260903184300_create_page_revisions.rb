class CreatePageRevisions < ActiveRecord::Migration[8.1]
  def change
    create_table :page_revisions do |t|
      t.references :page, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.jsonb :content, null: false, default: []
      t.string :label, null: false, default: ""
      t.datetime :created_at, null: false
    end

    add_index :page_revisions, [ :page_id, :created_at ]
  end
end
