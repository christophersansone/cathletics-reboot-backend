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

      PARTSTAT_MAP = { "yes" => "ACCEPTED", "no" => "DECLINED", "maybe" => "TENTATIVE" }.freeze

      def build_ical_feed(schedulable, from_time, to_time)
        return empty_calendar_ical unless schedulable.respond_to?(:scheduled_events)

        events = schedulable.scheduled_events.to_a
        event_ids = events.map(&:id)
        my_rsvps = preload_user_rsvps(event_ids)
        rsvp_counts = preload_rsvp_counts(event_ids)

        cal = Icalendar::Calendar.new
        cal.append_custom_property("X-WR-CALNAME", schedulable_ical_name(schedulable))

        events.each do |event|
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
            ical_event.append_custom_property("X-RECURRING", event.recurring? ? "true" : "false")
            if occ[:cancelled]
              ical_event.append_custom_property("STATUS", "CANCELLED")
              ical_event.append_custom_property("X-CANCELLATION-REASON", occ[:cancellation_reason].to_s)
            end

            ical_event.append_custom_property("X-RSVP-MODE", event.rsvp_mode)

            unless event.rsvp_mode_none?
              add_current_user_attendee(ical_event, event, occ[:start_at], my_rsvps)

              counts = rsvp_counts[[event.id, occ[:start_at].to_i]] || {}
              ical_event.append_custom_property("X-RSVP-YES-COUNT", (counts["yes"] || 0).to_s)
              ical_event.append_custom_property("X-RSVP-NO-COUNT", (counts["no"] || 0).to_s)
              ical_event.append_custom_property("X-RSVP-MAYBE-COUNT", (counts["maybe"] || 0).to_s)
            end

            cal.add_event(ical_event)
          end
        end

        cal.to_ical
      end

      def preload_user_rsvps(event_ids)
        return {} if event_ids.empty?

        rsvps = ScheduledEventRsvp
          .where(scheduled_event_id: event_ids, user_id: current_user.id)
        result = {}
        rsvps.each do |rsvp|
          result[[rsvp.scheduled_event_id, rsvp.occurrence_start_at.to_i]] = rsvp
        end
        result
      end

      def preload_rsvp_counts(event_ids)
        return {} if event_ids.empty?

        rsvps = ScheduledEventRsvp
          .where(scheduled_event_id: event_ids)
          .select(:scheduled_event_id, :occurrence_start_at, :response)
        result = Hash.new { |h, k| h[k] = { "yes" => 0, "no" => 0, "maybe" => 0 } }
        rsvps.each do |rsvp|
          result[[rsvp.scheduled_event_id, rsvp.occurrence_start_at.to_i]][rsvp.response] += 1
        end
        result
      end

      def add_current_user_attendee(ical_event, event, occurrence_start_at, my_rsvps)
        rsvp = my_rsvps[[event.id, occurrence_start_at.to_i]]
        partstat = rsvp ? PARTSTAT_MAP.fetch(rsvp.response, "NEEDS-ACTION") : "NEEDS-ACTION"
        cal_uri = current_user.email.present? ? "mailto:#{current_user.email}" : "urn:cathletics:user:#{current_user.id}"

        params = {
          "PARTSTAT" => partstat,
          "CN" => current_user.full_name,
          "X-USER-ID" => current_user.id.to_s
        }
        params["X-RSVP-ID"] = rsvp.id.to_s if rsvp

        ical_event.attendee = [Icalendar::Values::CalAddress.new(cal_uri, params)]
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
