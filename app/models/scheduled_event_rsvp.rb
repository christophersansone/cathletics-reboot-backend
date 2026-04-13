# frozen_string_literal: true

class ScheduledEventRsvp < ApplicationRecord
  include SoftDeletable

  enum :response, { no: 0, yes: 1, maybe: 2 }, prefix: true

  belongs_to :scheduled_event
  belongs_to :user
  belongs_to :responded_by, class_name: "User", optional: true

  validates :response, presence: true
  validates :occurrence_start_at, presence: true
  validates :user_id, uniqueness: {
    scope: [:scheduled_event_id, :occurrence_start_at],
    conditions: -> { where(deleted_at: nil) }
  }
  validate :rsvp_mode_must_allow_responses
  validate :response_must_match_rsvp_mode

  private

  def rsvp_mode_must_allow_responses
    return unless scheduled_event

    if scheduled_event.rsvp_mode_none?
      errors.add(:base, "RSVPs are not enabled for this event")
    end
  end

  def response_must_match_rsvp_mode
    return unless scheduled_event
    return if scheduled_event.rsvp_mode_none?
    return if response.blank?

    if scheduled_event.rsvp_mode_regrets_only? && !response_no?
      errors.add(:response, "must be 'no' for regrets-only events")
    end
  end
end
