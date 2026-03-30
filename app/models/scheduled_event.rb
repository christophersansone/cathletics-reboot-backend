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
  # Returns array of hashes: { start_at:, end_at:, cancelled:, cancellation_reason: }
  # exdates = "removed" (omitted from list). cancelled_occurrences / cancelled_from = "cancelled" (included with reason).
  def occurrences_between(from_time, to_time)
    from_time = from_time.to_time.utc
    to_time = to_time.to_time.utc
    if rrule.blank?
      return [] if exdate?(start_at.utc)

      occ = single_occurrence
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
    cancelled, reason = cancellation_for(start_at.utc)
    {
      start_at: start_at.utc,
      end_at: end_at.utc,
      cancelled: cancelled,
      cancellation_reason: reason
    }
  end

  def exdate?(dt)
    return false if exdates.blank?

    exdates.is_a?(Array) && exdates.any? { |d| time_in_exdates?(dt, d) }
  end

  # Returns [cancelled?, reason] for this occurrence start time.
  def cancellation_for(occurrence_start)
    if cancelled_from.present? && occurrence_start >= cancelled_from.utc
      return true, cancellation_reason.presence
    end
    return false, nil if self.cancelled_occurrences.blank?

    list = Array.wrap(self.cancelled_occurrences)
    entry = list.find { |e| time_matches_occurrence?(occurrence_start, e) }
    entry ? [true, cancellation_entry_reason(entry)] : [false, nil]
  end

  def cancellation_entry_reason(entry)
    return unless entry.is_a?(Hash)

    (entry["reason"].presence || entry[:reason].presence)
  end

  def time_matches_occurrence?(dt, entry)
    start_val = entry.is_a?(Hash) ? (entry["start_at"].presence || entry[:start_at]) : nil
    return false unless start_val.present?

    parsed = Time.zone.parse(start_val.to_s)&.utc
    return false unless parsed

    (dt.to_i - parsed.to_i).abs < 2
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

      cancelled, reason = cancellation_for(start_utc)
      occurrences << { start_at: start_utc, end_at: end_utc, cancelled: cancelled, cancellation_reason: reason }
    end
    occurrences
  end

  # EXDATE values for Icalendar must be Time-like. Strings must be parsed: ActiveSupport::StringInquirer
  # makes ISO strings respond to `to_time`, so we must not pass raw strings through to the gem.
  def parse_exdate(d)
    t =
      if d.is_a?(String)
        Time.zone.parse(d)
      elsif d.is_a?(Time)
        d
      elsif defined?(ActiveSupport::TimeWithZone) && d.is_a?(ActiveSupport::TimeWithZone)
        d
      elsif d.respond_to?(:to_time)
        d.to_time
      else
        Time.zone.parse(d.to_s)
      end
    t&.utc
  end
end
