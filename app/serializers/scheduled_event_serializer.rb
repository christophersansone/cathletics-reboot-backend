# frozen_string_literal: true

class ScheduledEventSerializer < BaseSerializer
  attributes :title, :description, :start_at, :end_at, :all_day, :rrule, :exdates

  attribute :time_zone do |event|
    event.effective_time_zone
  end

  belongs_to :schedulable
end
