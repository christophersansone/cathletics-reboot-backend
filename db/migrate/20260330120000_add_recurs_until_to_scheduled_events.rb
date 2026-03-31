# frozen_string_literal: true

require "icalendar"
require "icalendar/recurrence"

class AddRecursUntilToScheduledEvents < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  class MigrationScheduledEvent < ApplicationRecord
    self.table_name = "scheduled_events"
  end

  def up
    add_column :scheduled_events, :recurs_until, :date
    MigrationScheduledEvent.reset_column_information

    say_with_time "Backfilling recurs_until and normalizing rrule" do
      MigrationScheduledEvent.unscoped.where(deleted_at: nil).find_each do |event|
        next if event.rrule.blank?

        stripped = strip_until_and_count(event.rrule)
        until_date =
          recurs_until_from_until_clause(event) ||
          recurs_until_from_count_clause(event)
        if until_date.nil? && stripped.present? && event.rrule.match?(/FREQ=/i) && !event.rrule.match?(/UNTIL|COUNT/i)
          until_date = event.start_at.utc.to_date + 365
        end

        attrs = {}
        attrs[:rrule] = stripped if stripped.present?
        attrs[:recurs_until] = until_date if until_date
        event.update_columns(attrs) if attrs.any?
      end
    end
  end

  def down
    remove_column :scheduled_events, :recurs_until
  end

  private

  def strip_until_and_count(rrule)
    return nil if rrule.blank?

    rrule.to_s.strip
      .sub(/;?\s*UNTIL=[^;]+/i, "")
      .sub(/;?\s*COUNT=\d+/i, "")
      .gsub(/^;+|;+$/, "")
      .gsub(/;{2,}/, ";")
      .strip.presence
  end

  def recurs_until_from_until_clause(event)
    m = event.rrule.match(/UNTIL=([^;\s]+)/i)
    return nil unless m

    raw = m[1]
    time =
      begin
        if raw.match?(/^\d{8}$/)
          Time.utc(raw[0, 4].to_i, raw[4, 2].to_i, raw[6, 2].to_i).end_of_day
        elsif raw.end_with?("Z")
          Time.zone.parse(raw)
        else
          Time.zone.parse(raw.gsub(/^(\d{4})(\d{2})(\d{2})T/, '\1-\2-\3T'))
        end
      rescue ArgumentError, TypeError
        nil
      end
    return nil unless time

    zone = Time.find_zone(event.read_attribute(:time_zone).presence || "UTC")
    time.utc.in_time_zone(zone).to_date
  end

  def recurs_until_from_count_clause(event)
    return nil unless event.rrule.match?(/COUNT=\d+/i)

    ical = Icalendar::Event.new
    ical.dtstart = event.start_at
    ical.dtend = event.end_at
    ical.rrule = event.rrule
    last_start = nil
    ical.occurrences_between(event.start_at - 1.day, 100.years.from_now).each do |occ|
      start_t = occ.respond_to?(:start_time) ? occ.start_time : occ
      last_start = start_t.respond_to?(:to_time) ? start_t.to_time : Time.zone.at(start_t)
    end
    return nil unless last_start

    zone = Time.find_zone(event.read_attribute(:time_zone).presence || "UTC")
    last_start.utc.in_time_zone(zone).to_date
  end
end
