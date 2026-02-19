class CreateLeagues < ActiveRecord::Migration[8.1]
  def change
    create_table :leagues do |t|
      t.references :season, null: false, foreign_key: true
      t.string :name
      t.integer :gender
      t.integer :min_grade
      t.integer :max_grade
      t.integer :min_age
      t.integer :max_age
      t.date :age_cutoff_date
      t.integer :capacity

      t.datetime :deleted_at
      t.timestamps
    end

    add_index :leagues, :deleted_at
  end
end
