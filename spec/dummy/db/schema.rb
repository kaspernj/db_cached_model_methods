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

ActiveRecord::Schema.define(version: 20151113082450) do

  create_table "user_caches", force: :cascade do |t|
    t.integer  "resource_id"
    t.string   "method_name"
    t.string   "unique_key"
    t.string   "string_value"
    t.integer  "integer_value"
    t.float    "float_value"
    t.datetime "time_value"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_caches", ["expires_at"], name: "index_user_caches_on_expires_at"
  add_index "user_caches", ["float_value"], name: "index_user_caches_on_float_value"
  add_index "user_caches", ["integer_value"], name: "index_user_caches_on_integer_value"
  add_index "user_caches", ["resource_id", "method_name", "unique_key"], name: "user_caches_unique_resource_method_key", unique: true
  add_index "user_caches", ["resource_id"], name: "index_user_caches_on_resource_id"
  add_index "user_caches", ["string_value"], name: "index_user_caches_on_string_value"
  add_index "user_caches", ["time_value"], name: "index_user_caches_on_time_value"

  create_table "users", force: :cascade do |t|
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
