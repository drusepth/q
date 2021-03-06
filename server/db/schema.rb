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

ActiveRecord::Schema.define(version: 20171204022849) do

  create_table "answers", force: :cascade do |t|
    t.integer  "question_id"
    t.string   "answer"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "source"
    t.string   "answerer"
  end

  add_index "answers", ["question_id"], name: "index_answers_on_question_id"

  create_table "phrasings", force: :cascade do |t|
    t.integer  "question_id"
    t.string   "phrasing"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "phrasings", ["question_id"], name: "index_phrasings_on_question_id"

  create_table "queries", force: :cascade do |t|
    t.integer  "phrasing_id"
    t.string   "seen_at"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "queries", ["phrasing_id"], name: "index_queries_on_phrasing_id"

  create_table "questions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "responses", force: :cascade do |t|
    t.integer  "question_id"
    t.integer  "answer_id"
    t.integer  "query_id"
    t.string   "seen_at"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "responses", ["answer_id"], name: "index_responses_on_answer_id"
  add_index "responses", ["query_id"], name: "index_responses_on_query_id"
  add_index "responses", ["question_id"], name: "index_responses_on_question_id"

end
