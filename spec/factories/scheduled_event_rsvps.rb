# frozen_string_literal: true

FactoryBot.define do
  factory :scheduled_event_rsvp do
    scheduled_event { association :scheduled_event, rsvp_mode: :full }
    user
    responded_by { association :user }
    occurrence_start_at { scheduled_event.start_at }
    response { :yes }
  end
end
