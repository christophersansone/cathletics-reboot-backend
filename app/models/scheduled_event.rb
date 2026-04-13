# frozen_string_literal: true

class ScheduledEvent < ApplicationRecord
  include SoftDeletable

  enum :rsvp_mode, { none: 0, full: 1, regrets_only: 2 }, prefix: true

  belongs_to :schedulable, polymorphic: true
  has_many :scheduled_event_rsvps, dependent: :destroy

  validates :title, presence: true
  validates :start_at, presence: true
  validates :end_at, presence: true
  validate :end_at_after_start_at
  validate :recurrence_must_be_consistent
  validate :recurs_until_on_or_after_start_date
  validate :exdates_must_be_calendar_dates

  # Optional: basic rrule presence check; full validation happens on expansion
  validates :rrule, length: { maximum: 1024 }, allow_blank: true

  before_validation :strip_rrule_until_and_count
  before_validation :normalize_cancelled_occurrences

  def effective_time_zone
    time_zone.presence || schedulable_organization&.time_zone || "UTC"
  end

  # `start_at` / `end_at` = first occurrence only (wall start/end of that instance).
  # `recurs_until` = last calendar day (in `effective_time_zone`) that may still have an occurrence.
  # `rrule` = repeat pattern only (FREQ, BYDAY, INTERVAL); never UNTIL/COUNT — end date is always `recurs_until`.
  def recurring?
    recurs_until.present? && rrule.present?
  end

  # Expand this event's occurrences in the given range (UTC).
  # Returns array of hashes: { start_at:, end_at:, cancelled:, cancellation_reason: }
  # exdates = "removed" (omitted from list). cancelled_occurrences / cancelled_from = "cancelled" (included with reason).
  def occurrences_between(from_time, to_time)
    from_time = from_time.to_time.utc
    to_time = to_time.to_time.utc
    unless recurring?
      return [] if exdate?(start_at.utc)

      occ = single_occurrence
      return [] if occ[:start_at] < from_time || occ[:start_at] > to_time
      return [occ]
    end

    expand_recurrence(from_time, to_time)
  end

  def self.strip_rrule_until_and_count(rrule)
    return nil if rrule.blank?

    rrule.to_s.strip
      .sub(/;?\s*UNTIL=[^;]+/i, "")
      .sub(/;?\s*COUNT=\d+/i, "")
      .gsub(/^;+|;+$/, "")
      .gsub(/;{2,}/, ";")
      .strip.presence
  end

  private

  def end_at_after_start_at
    return if end_at.blank? || start_at.blank?

    errors.add(:end_at, "must be after start_at") if end_at <= start_at
  end

  def strip_rrule_until_and_count
    self.rrule = self.class.strip_rrule_until_and_count(rrule)
  end

  def normalize_cancelled_occurrences
    self.cancelled_occurrences = [] if cancelled_occurrences.nil?
    return if cancelled_occurrences.blank?

    raw = Array.wrap(cancelled_occurrences)
    normalized = []
    raw.each_with_index do |entry, idx|
      unless entry.is_a?(Hash)
        errors.add(:cancelled_occurrences, "entry #{idx} must be a hash with start_at")
        return
      end

      ind = entry.with_indifferent_access
      start_raw = ind[:start_at]
      if start_raw.blank?
        errors.add(:cancelled_occurrences, "entry #{idx} must include start_at")
        return
      end

      parsed = Time.zone.parse(start_raw.to_s)&.utc
      unless parsed
        errors.add(:cancelled_occurrences, "entry #{idx} has invalid start_at")
        return
      end

      row = { "start_at" => parsed.iso8601 }
      row["reason"] = ind[:reason].to_s if ind[:reason].present?
      normalized << row
    end

    self.cancelled_occurrences = normalized
  end

  def recurrence_must_be_consistent
    if recurs_until.present? && rrule.blank?
      errors.add(:rrule, "must be present when recurs_until is set")
    end

    if rrule.present? && recurs_until.blank?
      errors.add(:recurs_until, "must be present when rrule is set")
    end
  end

  def recurs_until_on_or_after_start_date
    return if recurs_until.blank? || start_at.blank?

    zone = Time.find_zone!(effective_time_zone)
    start_date = start_at.in_time_zone(zone).to_date
    return if recurs_until >= start_date

    errors.add(:recurs_until, "must be on or after the first event date (#{effective_time_zone})")
  end

  # RRULE UNTIL must be UTC in compact form; use end of recurs_until calendar day in event TZ.
  def rrule_until_utc_suffix
    z = Time.find_zone!(effective_time_zone)
    end_time = z.local(recurs_until.year, recurs_until.month, recurs_until.day).end_of_day.utc
    end_time.strftime("%Y%m%dT%H%M%SZ")
  end

  def rrule_for_expansion
    base = rrule.to_s.strip
    raise ArgumentError, "rrule blank for recurring event" if base.blank?

    "#{base};UNTIL=#{rrule_until_utc_suffix}"
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
    return false if exdates.blank? || !exdates.is_a?(Array)

    exdates.any? { |d| time_in_exdates?(dt, d) }
  end

  # Returns [cancelled?, reason] for this occurrence start time.
  def cancellation_for(occurrence_start)
    if cancelled_from.present? && occurrence_start >= cancelled_from.utc
      return true, cancellation_reason.presence
    end
    return false, nil if cancelled_occurrences.blank?

    list = Array.wrap(cancelled_occurrences)
    entry = list.find { |e| time_matches_occurrence?(occurrence_start, e) }
    entry ? [true, entry["reason"].presence] : [false, nil]
  end

  def time_matches_occurrence?(dt, entry)
    start_val = entry["start_at"]
    return false unless start_val.present?

    parsed = Time.zone.parse(start_val.to_s)&.utc
    return false unless parsed

    (dt.to_i - parsed.to_i).abs < 2
  end

  # exdates: ISO 8601 calendar dates only ("YYYY-MM-dd") — omitted occurrences on that day in `effective_time_zone`.
  # Callers pass UTC `Time` instances (expanded occurrences or `start_at.utc`).
  def time_in_exdates?(dt, d)
    zone = Time.find_zone!(effective_time_zone)
    coerce_time_utc(dt).in_time_zone(zone).to_date == Date.iso8601(d)
  end

  def coerce_time_utc(dt)
    dt.respond_to?(:utc) ? dt.utc : Time.zone.parse(dt.to_s).utc
  end

  # icalendar ~2.12 / icalendar-recurrence ~1.2 may yield objects with start_time/end_time or plain time-like values.
  def icalendar_occurrence_bounds(occ, duration_seconds)
    start_t = occ.respond_to?(:start_time) ? occ.start_time : occ
    end_t = occ.respond_to?(:end_time) ? occ.end_time : (start_t + duration_seconds)
    start_utc = start_t.respond_to?(:to_time) ? start_t.to_time.utc : Time.zone.at(start_t).utc
    end_utc = end_t.respond_to?(:to_time) ? end_t.to_time.utc : Time.zone.at(end_t).utc
    [start_utc, end_utc]
  end

  def expand_recurrence(from_time, to_time)
    require "icalendar"
    require "icalendar/recurrence"

    event = Icalendar::Event.new
    event.dtstart = start_at
    event.dtend = end_at
    event.rrule = rrule_for_expansion
    if exdates.is_a?(Array) && exdates.present?
      exdate_times = exdates.filter_map { |d| parse_exdate(d) }
      event.exdate = exdate_times if exdate_times.any?
    end

    duration_seconds = end_at.to_i - start_at.to_i
    occurrences = []
    event.occurrences_between(from_time, to_time).each do |occ|
      start_utc, end_utc = icalendar_occurrence_bounds(occ, duration_seconds)
      next if exdate?(start_utc)

      cancelled, reason = cancellation_for(start_utc)
      occurrences << { start_at: start_utc, end_at: end_utc, cancelled: cancelled, cancellation_reason: reason }
    end
    occurrences
  end

  # EXDATE instants for Icalendar: same local time-of-day as the series `start_at`, on the given calendar day.
  def parse_exdate(d)
    zone = Time.find_zone!(effective_time_zone)
    day = Date.iso8601(d)
    start_local = start_at.in_time_zone(zone)
    start_local.change(year: day.year, month: day.month, day: day.day).utc
  end

  def exdates_must_be_calendar_dates
    return if exdates.blank?

    unless exdates.is_a?(Array)
      errors.add(:exdates, "must be an array")
      return
    end

    exdates.each do |entry|
      unless entry.is_a?(String)
        errors.add(:exdates, "must use ISO 8601 calendar date strings (YYYY-MM-dd)")
        return
      end

      unless entry.match?(/\A\d{4}-\d{2}-\d{2}\z/)
        errors.add(:exdates, "must use YYYY-MM-dd format")
        return
      end

      begin
        Date.iso8601(entry)
      rescue ArgumentError, Date::Error
        errors.add(:exdates, "contains invalid calendar date: #{entry.inspect}")
        return
      end
    end
  end
end
