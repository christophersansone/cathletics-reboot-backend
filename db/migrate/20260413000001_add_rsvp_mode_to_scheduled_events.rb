# frozen_string_literal: true

class AddRsvpModeToScheduledEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :scheduled_events, :rsvp_mode, :integer, default: 0, null: false
  end
end
