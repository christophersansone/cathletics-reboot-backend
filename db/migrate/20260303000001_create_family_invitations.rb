class CreateFamilyInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :family_invitations do |t|
      t.references :family, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.integer :role, null: false
      t.string :token, null: false
      t.datetime :expires_at
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :family_invitations, :token, unique: true, where: "deleted_at IS NULL"
    add_index :family_invitations, :deleted_at
  end
end
