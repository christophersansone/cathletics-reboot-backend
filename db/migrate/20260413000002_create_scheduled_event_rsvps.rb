# frozen_string_literal: true

class CreateScheduledEventRsvps < ActiveRecord::Migration[8.1]
  def change
    create_table :scheduled_event_rsvps do |t|
      t.references :scheduled_event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :responded_by, foreign_key: { to_table: :users }
      t.datetime :occurrence_start_at, null: false
      t.integer :response, null: false
      t.text :note
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :scheduled_event_rsvps, :deleted_at
    add_index :scheduled_event_rsvps,
      [:scheduled_event_id, :user_id, :occurrence_start_at],
      unique: true,
      where: "deleted_at IS NULL",
      name: "idx_scheduled_event_rsvps_unique_per_occurrence"
  end
end
