# frozen_string_literal: true

require "icalendar"

module Api
  module V1
    class ScheduledEventOccurrencesController < BaseController
      before_action :set_schedulable

      def index
        authorize! :read, @schedulable
        from_time = parse_time_param(:from)
        to_time = parse_time_param(:to)
        from_time ||= Time.current.beginning_of_month
        to_time ||= Time.current.end_of_month + 1.month

        ical = build_ical_feed(@schedulable, from_time, to_time)
        response.headers["Content-Disposition"] = "inline; filename=\"schedule.ics\""
        render plain: ical, content_type: "text/calendar"
      end

      private

      def set_schedulable
        type = params[:schedulable_type].to_s.presence
        id = params[:schedulable_id].to_s.presence
        raise ActiveRecord::RecordNotFound, "schedulable_type and schedulable_id required" if type.blank? || id.blank?

        klass = type.singularize.classify.constantize
        @schedulable = klass.find(id)
      end

      def parse_time_param(key)
        value = params[key]
        return nil if value.blank?

        Time.zone.parse(value.to_s)&.utc
      end

      def build_ical_feed(schedulable, from_time, to_time)
        return empty_calendar_ical unless schedulable.respond_to?(:scheduled_events)

        cal = Icalendar::Calendar.new
        cal.append_custom_property("X-WR-CALNAME", schedulable_ical_name(schedulable))

        schedulable.scheduled_events.each do |event|
          event.occurrences_between(from_time, to_time).each do |occ|
            ical_event = Icalendar::Event.new
            # Use explicit UTC (…Z) so clients like ical.js match Wall times to DB/recurrence UTC.
            # Floating DTSTART (no zone) makes JS interpret in local TZ; cancellation PATCH then
            # stores a different instant and server-side cancellation matching fails → no STATUS in feed.
            ical_event.dtstart = ical_datetime_utc(occ[:start_at])
            ical_event.dtend = ical_datetime_utc(occ[:end_at])
            ical_event.summary = event.title
            ical_event.description = event.description if event.description.present?
            ical_event.uid = "cathletics-event-#{event.id}-#{occ[:start_at].to_i}@cathletics"
            ical_event.append_custom_property("X-EVENT-ID", event.id.to_s)
            ical_event.append_custom_property("X-TZID", event.effective_time_zone)
            ical_event.append_custom_property("X-RECURRING", event.rrule.present? ? "true" : "false")
            if occ[:cancelled]
              ical_event.append_custom_property("STATUS", "CANCELLED")
              ical_event.append_custom_property("X-CANCELLATION-REASON", occ[:cancellation_reason].to_s)
            end
            cal.add_event(ical_event)
          end
        end

        cal.to_ical
      end

      def schedulable_ical_name(schedulable)
        return "Schedule" unless schedulable.respond_to?(:name)

        "#{schedulable.name} Schedule"
      end

      def empty_calendar_ical
        Icalendar::Calendar.new.to_ical
      end

      def ical_datetime_utc(time)
        t = time.respond_to?(:to_time) ? time.to_time : Time.zone.parse(time.to_s)
        t = t.utc
        Icalendar::Values::DateTime.new(t.strftime("%Y%m%dT%H%M%SZ"))
      end
    end
  end
end
