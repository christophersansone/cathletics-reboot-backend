class CreateFamilies < ActiveRecord::Migration[8.1]
  def change
    create_table :families do |t|
      t.string :name, null: false

      t.datetime :deleted_at
      t.timestamps
    end

    add_index :families, :deleted_at
  end
end
