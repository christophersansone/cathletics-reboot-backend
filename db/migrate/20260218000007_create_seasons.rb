class CreateSeasons < ActiveRecord::Migration[8.1]
  def change
    create_table :seasons do |t|
      t.references :activity_type, null: false, foreign_key: true
      t.string :name, null: false
      t.date :start_date
      t.date :end_date
      t.datetime :registration_start_at
      t.datetime :registration_end_at

      t.datetime :deleted_at
      t.timestamps
    end

    add_index :seasons, [:activity_type_id, :name], unique: true, where: "deleted_at IS NULL"
    add_index :seasons, :deleted_at
  end
end
