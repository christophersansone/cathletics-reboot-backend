class CreateFamilyMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :family_memberships do |t|
      t.references :family, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false

      t.datetime :deleted_at
      t.timestamps
    end

    add_index :family_memberships, [:family_id, :user_id], unique: true, where: "deleted_at IS NULL"
    add_index :family_memberships, :deleted_at
  end
end
