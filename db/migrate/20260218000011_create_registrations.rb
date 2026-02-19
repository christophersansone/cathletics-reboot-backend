class CreateRegistrations < ActiveRecord::Migration[8.1]
  def change
    create_table :registrations do |t|
      t.references :league, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :registered_by, null: false, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0

      t.datetime :deleted_at
      t.timestamps
    end

    add_index :registrations, [:league_id, :user_id], unique: true, where: "deleted_at IS NULL"
    add_index :registrations, :deleted_at
  end
end
