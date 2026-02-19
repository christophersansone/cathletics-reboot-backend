class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :password_digest
      t.string :nickname
      t.date :date_of_birth
      t.integer :grade_level
      t.integer :gender

      t.datetime :deleted_at
      t.timestamps
    end

    add_index :users, :email, unique: true, where: "deleted_at IS NULL"
    add_index :users, :deleted_at
  end
end
