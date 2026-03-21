# frozen_string_literal: true

class AddCancellationToScheduledEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :scheduled_events, :cancelled_occurrences, :jsonb, default: [], null: false
    add_column :scheduled_events, :cancelled_from, :datetime
    add_column :scheduled_events, :cancellation_reason, :string
  end
end
