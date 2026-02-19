class CreateOrganizationMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_memberships do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 1

      t.datetime :deleted_at
      t.timestamps
    end

    add_index :organization_memberships, [:organization_id, :user_id], unique: true, where: "deleted_at IS NULL", name: "idx_org_memberships_unique_org_user"
    add_index :organization_memberships, :deleted_at
  end
end
