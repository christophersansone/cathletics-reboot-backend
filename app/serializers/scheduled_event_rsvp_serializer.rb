# frozen_string_literal: true

class ScheduledEventRsvpSerializer < BaseSerializer
  attributes :response, :occurrence_start_at, :note, :created_at, :updated_at

  belongs_to :scheduled_event
  belongs_to :user
  belongs_to :responded_by
end
