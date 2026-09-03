class CreateDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :domains do |t|
      t.references :site, null: false, foreign_key: true
      t.string :host, null: false

      # The primary domain is the one canonical URLs are built from; requests
      # arriving on the others are redirected to it.
      t.boolean :primary, null: false, default: false

      # Caddy asks for permission before ordering a certificate for a name it
      # has not seen. Without that gate, anyone pointing their own domain at
      # this server could burn through the Let's Encrypt rate limit for us.
      t.datetime :dns_checked_at
      t.datetime :certified_at
      t.string :last_error

      t.timestamps
    end

    add_index :domains, :host, unique: true
    add_index :domains, [ :site_id, :primary ]
  end
end
