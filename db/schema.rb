# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140106123529) do

  create_table "categories", force: true do |t|
    t.string   "name"
    t.string   "un"
    t.string   "slug"
    t.integer  "weight",          default: 0
    t.boolean  "active",          default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "default_item_id"
  end

  add_index "categories", ["slug"], name: "index_categories_on_slug", unique: true
  add_index "categories", ["un"], name: "index_categories_on_un", unique: true
  add_index "categories", ["weight", "active"], name: "index_categories_on_weight_and_active"

  create_table "category_items", force: true do |t|
    t.integer  "category_id"
    t.string   "name"
    t.integer  "weight",      default: 0
    t.boolean  "active",      default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "color"
  end

  add_index "category_items", ["category_id"], name: "index_category_items_on_category_id"
  add_index "category_items", ["weight", "active"], name: "index_category_items_on_weight_and_active"
  add_index "category_items", ["weight"], name: "index_category_items_on_weight"

  create_table "ckeditor_assets", force: true do |t|
    t.string   "data_file_name",               null: false
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.integer  "assetable_id"
    t.string   "assetable_type",    limit: 30
    t.string   "type",              limit: 30
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ckeditor_assets", ["assetable_type", "assetable_id"], name: "idx_ckeditor_assetable"
  add_index "ckeditor_assets", ["assetable_type", "type", "assetable_id"], name: "idx_ckeditor_assetable_type"

  create_table "contacts", force: true do |t|
    t.text     "info"
    t.boolean  "active",           default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "properties_count"
  end

  add_index "contacts", ["info"], name: "idx_contacts_on_info"
  add_index "contacts", ["info"], name: "index_contacts_on_info"

  create_table "images", force: true do |t|
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "property_id"
    t.string   "title"
    t.text     "description"
    t.integer  "weight",             default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "images", ["property_id"], name: "index_images_on_property_id"

  create_table "properties", force: true do |t|
    t.integer  "contact_id"
    t.integer  "price1",         limit: 255
    t.integer  "price2",         limit: 255
    t.integer  "price3",         limit: 255
    t.text     "landmark"
    t.text     "more_info"
    t.date     "last_call_date"
    t.date     "request_date"
    t.date     "clear_date"
    t.date     "rental_date"
    t.boolean  "viewed",                     default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "address"
    t.string   "state"
    t.string   "rooms"
    t.string   "floor"
    t.string   "floors"
  end

  add_index "properties", ["address"], name: "idx_properties_on_address"
  add_index "properties", ["contact_id"], name: "index_properties_on_contact_id"
  add_index "properties", ["more_info"], name: "idx_properties_on_more_info"

  create_table "property_category_items", force: true do |t|
    t.integer  "property_id"
    t.integer  "category_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "property_category_items", ["category_item_id"], name: "index_property_category_items_on_category_item_id"
  add_index "property_category_items", ["property_id", "category_item_id"], name: "index_property_category_item_id"
  add_index "property_category_items", ["property_id"], name: "index_property_category_items_on_property_id"

  create_table "user_categories", force: true do |t|
    t.integer  "user_id"
    t.integer  "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_categories", ["user_id", "category_id"], name: "index_user_categories_on_user_id_and_category_id"

  create_table "user_category_items", force: true do |t|
    t.integer  "user_id"
    t.integer  "category_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_category_items", ["user_id", "category_item_id"], name: "index_user_category_item_id"

  create_table "users", force: true do |t|
    t.string   "username",                           default: "",    null: false
    t.string   "email",                              default: "",    null: false
    t.string   "encrypted_password",                 default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "price_from",             limit: 255
    t.integer  "price_to",               limit: 255
    t.boolean  "is_main",                            default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  add_index "users", ["username"], name: "index_users_on_username", unique: true

end
