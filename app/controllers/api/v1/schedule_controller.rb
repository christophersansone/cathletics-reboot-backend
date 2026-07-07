# frozen_string_literal: true

module Api
  module V1
    # Family-wide schedule: all upcoming occurrences across every team that
    # the current user or their children are on.
    class ScheduleController < BaseController
      include FamilyParticipants

      DEFAULT_WINDOW = 60.days

      def show
        render json: { data: { occurrences: occurrences_data } }
      end

      private

      def from_time
        @from_time ||= parse_time_param(:from) || Time.current.beginning_of_day
      end

      def to_time
        @to_time ||= parse_time_param(:to) || from_time + DEFAULT_WINDOW
      end

      def parse_time_param(key)
        value = params[key]
        return nil if value.blank?

        Time.zone.parse(value.to_s)&.utc
      end

      def team_memberships
        @team_memberships ||= TeamMembership
          .where(user_id: participant_ids)
          .includes(team: { league: { season: { activity_type: :organization } } })
      end

      def teams_by_id
        @teams_by_id ||= team_memberships.map(&:team).uniq.index_by(&:id)
      end

      def members_by_team_id
        @members_by_team_id ||= team_memberships.group_by(&:team_id)
      end

      def events
        @events ||= ScheduledEvent
          .where(schedulable_type: "Team", schedulable_id: teams_by_id.keys)
          .to_a
      end

      def rsvps_by_key
        @rsvps_by_key ||= begin
          rsvps = ScheduledEventRsvp.where(
            scheduled_event_id: events.map(&:id),
            user_id: participant_ids
          )
          rsvps.index_by { |r| [r.scheduled_event_id, r.occurrence_start_at.to_i, r.user_id] }
        end
      end

      def occurrences_data
        result = events.flat_map do |event|
          team = teams_by_id[event.schedulable_id]
          event.occurrences_between(from_time, to_time).map do |occ|
            occurrence_json(event, team, occ)
          end
        end
        result.sort_by { |o| o[:startAt] }
      end

      def occurrence_json(event, team, occ)
        league = team.league
        season = league.season
        activity_type = season.activity_type

        {
          eventId: event.id,
          title: event.title,
          description: event.description,
          startAt: occ[:start_at].utc.iso8601,
          endAt: occ[:end_at]&.utc&.iso8601,
          allDay: event.all_day,
          timeZone: event.effective_time_zone,
          recurring: event.recurring?,
          cancelled: !!occ[:cancelled],
          cancellationReason: occ[:cancellation_reason],
          rsvpMode: event.rsvp_mode,
          team: { id: team.id, name: team.name },
          league: { id: league.id, name: league.name.presence || league.auto_generated_name },
          activityType: { id: activity_type.id, name: activity_type.name },
          organization: { id: activity_type.organization.id, name: activity_type.organization.name },
          participants: participants_json(event, team, occ)
        }
      end

      def participants_json(event, team, occ)
        memberships = members_by_team_id[team.id] || []
        memberships.map do |membership|
          user = participants[membership.user_id]
          next unless user

          rsvp = rsvps_by_key[[event.id, occ[:start_at].to_i, user.id]]
          compact_user(user).merge(
            role: membership.role,
            rsvp: rsvp && { id: rsvp.id, response: rsvp.response }
          )
        end.compact
      end
    end
  end
end
