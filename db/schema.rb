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

ActiveRecord::Schema.define(:version => 20140426231552) do

  create_table "notebooks", :force => true do |t|
    t.string   "title"
    t.string   "modview"
    t.integer  "user_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.string   "guid"
    t.string   "eng"
    t.boolean  "trashed",    :default => false
  end

  create_table "notes", :force => true do |t|
    t.text     "title"
    t.string   "subtitle"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.string   "guid"
    t.string   "parent_id"
    t.integer  "rank"
    t.integer  "depth"
    t.boolean  "collapsed",   :default => false
    t.boolean  "fresh",       :default => true
    t.string   "eng"
    t.integer  "notebook_id"
    t.boolean  "trashed",     :default => false
    t.integer  "usn"
    t.string   "attachment"
  end

  create_table "users", :force => true do |t|
    t.string   "token_credentials"
    t.string   "email"
    t.boolean  "admin",                  :default => false
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "encrypted_password",     :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0,     :null => false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "failed_attempts",        :default => 0,     :null => false
    t.datetime "locked_at"
    t.integer  "last_update_count",      :default => 0
    t.datetime "last_full_sync"
    t.integer  "active_notebook"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
