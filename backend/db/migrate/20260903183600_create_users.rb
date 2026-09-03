class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name, null: false, default: ""

      # The first account created during setup owns the installation.
      t.string :role, null: false, default: "owner"

      # A second factor is mandatory, but it is enrolled after the first sign-in:
      # the secret is stored as soon as the QR code is shown, and a separate
      # timestamp records that the user proved they can generate codes from it.
      t.string :otp_secret
      t.datetime :otp_confirmed_at
      t.string :recovery_codes, array: true, null: false, default: []

      t.datetime :last_login_at
      t.integer :failed_attempts, null: false, default: 0
      t.datetime :locked_until

      t.timestamps
    end

    # Postgres compares strings case-sensitively, so addresses are stored
    # already downcased and this unique index enforces one account per address.
    add_index :users, :email, unique: true
  end
end
