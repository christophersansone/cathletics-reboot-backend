# frozen_string_literal: true

class ScheduledEventSerializer < BaseSerializer
  attributes :title, :description, :start_at, :end_at, :all_day, :rrule, :recurs_until, :exdates, :cancelled_occurrences, :cancelled_from, :cancellation_reason, :rsvp_mode

  attribute :time_zone do |event|
    event.effective_time_zone
  end

  belongs_to :schedulable
  has_many :scheduled_event_rsvps, link: ->(event) { url_helpers.api_v1_scheduled_event_rsvps_url(scheduled_event_id: event.id) }
end
