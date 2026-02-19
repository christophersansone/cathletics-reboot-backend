class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.datetime :deleted_at
      t.timestamps
    end

    add_index :organizations, :slug, unique: true, where: "deleted_at IS NULL"
    add_index :organizations, :deleted_at
  end
end
