# frozen_string_literal: true

class CreateScheduledEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :scheduled_events do |t|
      t.references :schedulable, polymorphic: true, null: false, index: true
      t.string :title, null: false
      t.text :description
      t.datetime :start_at, null: false
      t.datetime :end_at, null: false
      t.string :time_zone
      t.boolean :all_day, default: false, null: false
      t.text :rrule
      t.jsonb :exdates, default: []

      t.datetime :deleted_at
      t.timestamps
    end

    add_index :scheduled_events, :deleted_at
    add_index :scheduled_events, [:schedulable_type, :schedulable_id]
  end
end
