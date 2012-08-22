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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120824084855) do

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "fb_likes", :force => true do |t|
    t.string "fb_id"
    t.string "name"
    t.string "category"
  end

  add_index "fb_likes", ["fb_id"], :name => "index_fb_likes_on_fb_id"

  create_table "friendships", :force => true do |t|
    t.integer "user_id"
    t.integer "friend_id"
  end

  create_table "likes", :force => true do |t|
    t.integer "user_id"
    t.integer "likee_id"
    t.string  "likee_type"
  end

  create_table "users", :force => true do |t|
    t.string  "name"
    t.string  "email"
    t.string  "first_name"
    t.string  "facebook_uid"
    t.string  "access_token"
    t.boolean "friends_fetched",        :default => false
    t.boolean "friends_likes_fetched",  :default => false
    t.boolean "likes_fetched",          :default => false
    t.boolean "friends_likes_fetching", :default => false
    t.boolean "unicorns",               :default => false
  end

end
