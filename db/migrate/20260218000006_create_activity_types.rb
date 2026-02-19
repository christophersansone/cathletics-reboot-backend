class CreateActivityTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_types do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description

      t.datetime :deleted_at
      t.timestamps
    end

    add_index :activity_types, [:organization_id, :name], unique: true, where: "deleted_at IS NULL"
    add_index :activity_types, :deleted_at
  end
end
