class CreateTeamMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :team_memberships do |t|
      t.references :team, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 0

      t.datetime :deleted_at
      t.timestamps
    end

    add_index :team_memberships, [:team_id, :user_id, :role], unique: true, where: "deleted_at IS NULL"
    add_index :team_memberships, :deleted_at
  end
end
