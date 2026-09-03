# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_03_184600) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "block_types", force: :cascade do |t|
    t.string "asset_path"
    t.text "build_log", default: "", null: false
    t.string "build_status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.string "description", default: "", null: false
    t.boolean "enabled", default: true, null: false
    t.string "icon", default: "puzzle", null: false
    t.string "key", null: false
    t.string "kind", default: "html", null: false
    t.string "name", null: false
    t.jsonb "schema", default: [], null: false
    t.bigint "site_id", null: false
    t.text "source", default: "", null: false
    t.text "template", default: "", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "key"], name: "index_block_types_on_site_id_and_key", unique: true
    t.index ["site_id"], name: "index_block_types_on_site_id"
  end

  create_table "domains", force: :cascade do |t|
    t.datetime "certified_at"
    t.datetime "created_at", null: false
    t.datetime "dns_checked_at"
    t.string "host", null: false
    t.string "last_error"
    t.boolean "primary", default: false, null: false
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.index ["host"], name: "index_domains_on_host", unique: true
    t.index ["site_id", "primary"], name: "index_domains_on_site_id_and_primary"
    t.index ["site_id"], name: "index_domains_on_site_id"
  end

  create_table "form_submissions", force: :cascade do |t|
    t.string "block_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.string "ip_address"
    t.bigint "page_id"
    t.boolean "read", default: false, null: false
    t.bigint "site_id", null: false
    t.index ["page_id"], name: "index_form_submissions_on_page_id"
    t.index ["site_id", "created_at"], name: "index_form_submissions_on_site_id_and_created_at"
    t.index ["site_id"], name: "index_form_submissions_on_site_id"
  end

  create_table "media_items", force: :cascade do |t|
    t.string "alt", default: "", null: false
    t.datetime "created_at", null: false
    t.bigint "site_id", null: false
    t.string "title", default: "", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["site_id"], name: "index_media_items_on_site_id"
    t.index ["user_id"], name: "index_media_items_on_user_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "role", default: "editor", null: false
    t.bigint "site_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["site_id"], name: "index_memberships_on_site_id"
    t.index ["user_id", "site_id"], name: "index_memberships_on_user_id_and_site_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "page_revisions", force: :cascade do |t|
    t.jsonb "content", default: [], null: false
    t.datetime "created_at", null: false
    t.string "label", default: "", null: false
    t.bigint "page_id", null: false
    t.bigint "user_id"
    t.index ["page_id", "created_at"], name: "index_page_revisions_on_page_id_and_created_at"
    t.index ["page_id"], name: "index_page_revisions_on_page_id"
    t.index ["user_id"], name: "index_page_revisions_on_user_id"
  end

  create_table "pages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "draft_content", default: [], null: false
    t.boolean "home", default: false, null: false
    t.bigint "parent_id"
    t.string "path", null: false
    t.integer "position", default: 0, null: false
    t.datetime "published_at"
    t.jsonb "published_content"
    t.string "seo_description"
    t.string "seo_image"
    t.string "seo_title"
    t.bigint "site_id", null: false
    t.string "slug", null: false
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_pages_on_parent_id"
    t.index ["site_id", "path"], name: "index_pages_on_site_id_and_path", unique: true
    t.index ["site_id", "status"], name: "index_pages_on_site_id_and_status"
    t.index ["site_id"], name: "index_pages_on_site_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_sessions_on_expires_at"
    t.index ["token_digest"], name: "index_sessions_on_token_digest", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "accent", default: "teal", null: false
    t.datetime "created_at", null: false
    t.string "locale", default: "ru", null: false
    t.string "name", null: false
    t.jsonb "navigation", default: [], null: false
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.jsonb "settings", default: {}, null: false
    t.string "slug", null: false
    t.string "theme", default: "light", null: false
    t.string "timezone", default: "Europe/Moscow", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_sites_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_login_at"
    t.datetime "locked_until"
    t.string "name", default: "", null: false
    t.datetime "otp_confirmed_at"
    t.string "otp_secret"
    t.string "password_digest", null: false
    t.string "recovery_codes", default: [], null: false, array: true
    t.string "role", default: "owner", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "webauthn_credentials", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.datetime "last_used_at"
    t.string "nickname", default: "", null: false
    t.string "public_key", null: false
    t.bigint "sign_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["external_id"], name: "index_webauthn_credentials_on_external_id", unique: true
    t.index ["user_id"], name: "index_webauthn_credentials_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "block_types", "sites"
  add_foreign_key "domains", "sites"
  add_foreign_key "form_submissions", "pages"
  add_foreign_key "form_submissions", "sites"
  add_foreign_key "media_items", "sites"
  add_foreign_key "media_items", "users"
  add_foreign_key "memberships", "sites"
  add_foreign_key "memberships", "users"
  add_foreign_key "page_revisions", "pages"
  add_foreign_key "page_revisions", "users"
  add_foreign_key "pages", "pages", column: "parent_id"
  add_foreign_key "pages", "sites"
  add_foreign_key "sessions", "users"
  add_foreign_key "webauthn_credentials", "users"
end
