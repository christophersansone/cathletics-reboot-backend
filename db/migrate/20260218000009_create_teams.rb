class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :teams do |t|
      t.references :league, null: false, foreign_key: true
      t.string :name, null: false

      t.datetime :deleted_at
      t.timestamps
    end

    add_index :teams, :deleted_at
  end
end
