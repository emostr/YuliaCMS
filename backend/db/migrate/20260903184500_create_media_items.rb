class CreateMediaItems < ActiveRecord::Migration[8.1]
  def change
    create_table :media_items do |t|
      t.references :site, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :title, null: false, default: ""

      # Alternative text, filled in from the media library and reused every
      # time the image is placed on a page.
      t.string :alt, null: false, default: ""

      t.timestamps
    end
  end
end
