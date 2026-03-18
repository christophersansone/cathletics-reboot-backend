# frozen_string_literal: true

class ScheduledEvent < ApplicationRecord
  include SoftDeletable

  belongs_to :schedulable, polymorphic: true

  validates :title, presence: true
  validates :start_at, presence: true
  validates :end_at, presence: true
  validate :end_at_after_start_at

  # Optional: basic rrule presence check; full validation happens on expansion
  validates :rrule, length: { maximum: 1024 }, allow_blank: true

  def effective_time_zone
    time_zone.presence || schedulable_organization&.time_zone || "UTC"
  end

  # Expand this event's occurrences in the given range (UTC).
  # Returns array of hashes: { start_at:, end_at:, cancelled: }
  def occurrences_between(from_time, to_time)
    from_time = from_time.to_time.utc
    to_time = to_time.to_time.utc
    if rrule.blank?
      occ = single_occurrence
      return [] if occ[:cancelled]
      return [] if occ[:start_at] < from_time || occ[:start_at] > to_time
      return [occ]
    end

    expand_recurrence(from_time, to_time)
  end

  private

  def end_at_after_start_at
    return if end_at.blank? || start_at.blank?

    errors.add(:end_at, "must be after start_at") if end_at <= start_at
  end

  def schedulable_organization
    return unless schedulable.respond_to?(:organization)

    schedulable.organization
  end

  def single_occurrence
    {
      start_at: start_at.utc,
      end_at: end_at.utc,
      cancelled: exdate?(start_at)
    }
  end

  def exdate?(dt)
    return false if exdates.blank?

    exdates.is_a?(Array) && exdates.any? { |d| time_in_exdates?(dt, d) }
  end

  def time_in_exdates?(dt, d)
    parsed = d.is_a?(String) ? Time.zone.parse(d) : d
    return false unless parsed

    parsed = parsed.utc
    dt = dt.utc if dt.respond_to?(:utc)
    parsed.to_i == dt.to_i
  end

  def expand_recurrence(from_time, to_time)
    require "icalendar"
    require "icalendar/recurrence"

    event = Icalendar::Event.new
    event.dtstart = start_at
    event.dtend = end_at
    event.rrule = rrule
    if exdates.present? && exdates.is_a?(Array)
      exdate_times = exdates.filter_map { |d| parse_exdate(d) }
      event.exdate = exdate_times if exdate_times.any?
    end

    duration_seconds = end_at.to_i - start_at.to_i
    occurrences = []
    event.occurrences_between(from_time, to_time).each do |occ|
      start_t = occ.respond_to?(:start_time) ? occ.start_time : occ
      end_t = occ.respond_to?(:end_time) ? occ.end_time : (start_t + duration_seconds)
      start_utc = start_t.respond_to?(:to_time) ? start_t.to_time.utc : Time.zone.at(start_t).utc
      end_utc = end_t.respond_to?(:to_time) ? end_t.to_time.utc : Time.zone.at(end_t).utc
      next if exdate?(start_utc)

      occurrences << { start_at: start_utc, end_at: end_utc, cancelled: false }
    end
    occurrences
  end

  def parse_exdate(d)
    return d if d.respond_to?(:to_time)

    Time.zone.parse(d.to_s)
  end
end
