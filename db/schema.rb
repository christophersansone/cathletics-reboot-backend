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

ActiveRecord::Schema[8.1].define(version: 2026_03_06_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activity_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_activity_types_on_deleted_at"
    t.index ["organization_id", "name"], name: "index_activity_types_on_organization_id_and_name", unique: true, where: "(deleted_at IS NULL)"
    t.index ["organization_id"], name: "index_activity_types_on_organization_id"
  end

  create_table "families", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_families_on_deleted_at"
  end

  create_table "family_invitations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.datetime "deleted_at"
    t.datetime "expires_at"
    t.bigint "family_id", null: false
    t.integer "role", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_family_invitations_on_created_by_id"
    t.index ["deleted_at"], name: "index_family_invitations_on_deleted_at"
    t.index ["family_id"], name: "index_family_invitations_on_family_id"
    t.index ["token"], name: "index_family_invitations_on_token", unique: true, where: "(deleted_at IS NULL)"
  end

  create_table "family_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.bigint "family_id", null: false
    t.integer "role", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["deleted_at"], name: "index_family_memberships_on_deleted_at"
    t.index ["family_id", "user_id"], name: "index_family_memberships_on_family_id_and_user_id", unique: true, where: "(deleted_at IS NULL)"
    t.index ["family_id"], name: "index_family_memberships_on_family_id"
    t.index ["user_id"], name: "index_family_memberships_on_user_id"
  end

  create_table "leagues", force: :cascade do |t|
    t.date "age_cutoff_date"
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "gender"
    t.integer "max_age"
    t.integer "max_grade"
    t.integer "min_age"
    t.integer "min_grade"
    t.string "name"
    t.bigint "season_id", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_leagues_on_deleted_at"
    t.index ["season_id"], name: "index_leagues_on_season_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.datetime "created_at", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.bigint "resource_owner_id", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "application_id"
    t.datetime "created_at", null: false
    t.integer "expires_in"
    t.string "previous_refresh_token", default: "", null: false
    t.string "refresh_token"
    t.bigint "resource_owner_id"
    t.datetime "revoked_at"
    t.string "scopes"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "redirect_uri"
    t.string "scopes", default: "", null: false
    t.string "secret", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "organization_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.bigint "organization_id", null: false
    t.integer "role", default: 1, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["deleted_at"], name: "index_organization_memberships_on_deleted_at"
    t.index ["organization_id", "user_id"], name: "idx_org_memberships_unique_org_user", unique: true, where: "(deleted_at IS NULL)"
    t.index ["organization_id"], name: "index_organization_memberships_on_organization_id"
    t.index ["user_id"], name: "index_organization_memberships_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "name", null: false
    t.string "slug", null: false
    t.string "time_zone", default: "America/New_York", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_organizations_on_deleted_at"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true, where: "(deleted_at IS NULL)"
  end

  create_table "registrations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.bigint "league_id", null: false
    t.bigint "registered_by_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["deleted_at"], name: "index_registrations_on_deleted_at"
    t.index ["league_id", "user_id"], name: "index_registrations_on_league_id_and_user_id", unique: true, where: "(deleted_at IS NULL)"
    t.index ["league_id"], name: "index_registrations_on_league_id"
    t.index ["registered_by_id"], name: "index_registrations_on_registered_by_id"
    t.index ["user_id"], name: "index_registrations_on_user_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.bigint "activity_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.date "end_date"
    t.string "name", null: false
    t.datetime "registration_end_at"
    t.datetime "registration_start_at"
    t.date "start_date"
    t.string "time_zone"
    t.datetime "updated_at", null: false
    t.index ["activity_type_id", "name"], name: "index_seasons_on_activity_type_id_and_name", unique: true, where: "(deleted_at IS NULL)"
    t.index ["activity_type_id"], name: "index_seasons_on_activity_type_id"
    t.index ["deleted_at"], name: "index_seasons_on_deleted_at"
  end

  create_table "team_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "position"
    t.integer "role", default: 0, null: false
    t.bigint "team_id", null: false
    t.string "uniform_number"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["deleted_at"], name: "index_team_memberships_on_deleted_at"
    t.index ["team_id", "user_id", "role"], name: "index_team_memberships_on_team_id_and_user_id_and_role", unique: true, where: "(deleted_at IS NULL)"
    t.index ["team_id"], name: "index_team_memberships_on_team_id"
    t.index ["user_id"], name: "index_team_memberships_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.bigint "league_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_teams_on_deleted_at"
    t.index ["league_id"], name: "index_teams_on_league_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.datetime "deleted_at"
    t.string "email"
    t.string "first_name", null: false
    t.integer "gender"
    t.integer "grade_level"
    t.string "last_name", null: false
    t.string "nickname"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(deleted_at IS NULL)"
  end

  add_foreign_key "activity_types", "organizations"
  add_foreign_key "family_invitations", "families"
  add_foreign_key "family_invitations", "users", column: "created_by_id"
  add_foreign_key "family_memberships", "families"
  add_foreign_key "family_memberships", "users"
  add_foreign_key "leagues", "seasons"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "organization_memberships", "organizations"
  add_foreign_key "organization_memberships", "users"
  add_foreign_key "registrations", "leagues"
  add_foreign_key "registrations", "users"
  add_foreign_key "registrations", "users", column: "registered_by_id"
  add_foreign_key "seasons", "activity_types"
  add_foreign_key "team_memberships", "teams"
  add_foreign_key "team_memberships", "users"
  add_foreign_key "teams", "leagues"
end
