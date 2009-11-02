# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091101193348) do

  create_table "clipboard_members", :force => true do |t|
    t.integer  "user_id"
    t.integer  "thing_id"
    t.integer  "tag_id"
    t.integer  "operation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "old_tags", :force => true do |t|
    t.integer  "thing_id",                                                 :null => false
    t.string   "key",        :limit => 30,                                 :null => false
    t.string   "term",       :limit => 30
    t.string   "blurb"
    t.decimal  "number",                   :precision => 18, :scale => 15
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "operations", :force => true do |t|
    t.string   "name",       :limit => 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "relationship_types", :force => true do |t|
    t.string "value", :limit => 30
  end

  create_table "relationships", :force => true do |t|
    t.integer  "src_thing_id",         :null => false
    t.integer  "dest_thing_id",        :null => false
    t.integer  "relationship_type_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tags", :force => true do |t|
    t.integer  "thing_id",                                                                :null => false
    t.string   "key",        :limit => 30,                                                :null => false
    t.string   "term",       :limit => 30
    t.string   "blurb"
    t.decimal  "number",                   :precision => 18, :scale => 15
    t.date     "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",                                                  :default => 1
  end

  create_table "term_group_members", :force => true do |t|
    t.integer "term_group_id",               :null => false
    t.string  "value",         :limit => 30, :null => false
  end

  create_table "term_groups", :force => true do |t|
    t.string "name", :null => false
  end

  create_table "thing_paths", :force => true do |t|
    t.integer  "target"
    t.integer  "node01"
    t.integer  "node02"
    t.integer  "node03"
    t.integer  "node04"
    t.integer  "node05"
    t.integer  "node06"
    t.integer  "node07"
    t.integer  "node08"
    t.integer  "node09"
    t.integer  "node10"
    t.integer  "node11"
    t.integer  "node12"
    t.integer  "node13"
    t.integer  "node14"
    t.integer  "node15"
    t.integer  "node16"
    t.integer  "node17"
    t.integer  "node18"
    t.integer  "node19"
    t.integer  "node20"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "thing_types", :force => true do |t|
    t.string "value", :limit => 30, :null => false
  end

  create_table "things", :force => true do |t|
    t.string   "name",       :limit => 30
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",                  :default => 1
  end

  create_table "users", :force => true do |t|
    t.string   "name",          :limit => 30
    t.string   "password_hash"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
