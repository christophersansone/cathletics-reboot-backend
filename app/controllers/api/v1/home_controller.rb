module Api
  module V1
    class HomeController < BaseController
      def show
        render json: { data: { activeRegistrations: active_registrations_data, openLeagues: open_leagues_data } }
      end

      private

      def participant_ids
        @participant_ids ||= begin
          family_ids = current_user.family_memberships.where(role: [:parent, :guardian]).pluck(:family_id)
          child_ids = FamilyMembership.where(family_id: family_ids, role: :child).pluck(:user_id)
          (child_ids + [current_user.id]).uniq
        end
      end

      def participants
        @participants ||= User.where(id: participant_ids).index_by(&:id)
      end

      def user_org_ids
        @user_org_ids ||= current_user.organization_memberships.pluck(:organization_id)
      end

      # --- Active Registrations ---

      def active_registrations
        @active_registrations ||= Registration
          .joins(league: { season: :activity_type })
          .where(user_id: participant_ids)
          .where.not(status: [:canceled, :not_selected])
          .where("seasons.end_date >= ?", Date.current)
          .includes(user: {}, league: { season: { activity_type: :organization } })
      end

      def active_registrations_data
        active_registrations.map do |reg|
          league = reg.league
          season = league.season
          activity_type = season.activity_type
          team_membership = team_memberships_by_user_and_league[[reg.user_id, league.id]]

          {
            id: reg.id,
            status: reg.status,
            user: compact_user(reg.user),
            league: { id: league.id, name: league.name.presence || league.auto_generated_name },
            season: { id: season.id, name: season.name, startDate: season.start_date, endDate: season.end_date },
            activityType: { id: activity_type.id, name: activity_type.name },
            organization: { id: activity_type.organization.id, name: activity_type.organization.name },
            team: team_membership ? { id: team_membership.team_id, name: team_membership.team.name, role: team_membership.role } : nil
          }
        end
      end

      def team_memberships_by_user_and_league
        @team_memberships_by_user_and_league ||= begin
          league_ids = active_registrations.map(&:league_id).uniq
          TeamMembership
            .joins(:team)
            .where(user_id: participant_ids, teams: { league_id: league_ids })
            .includes(:team)
            .index_by { |tm| [tm.user_id, tm.team.league_id] }
        end
      end

      # --- Open Leagues ---

      def open_leagues
        @open_leagues ||= League
          .joins(season: :activity_type)
          .where(activity_types: { organization_id: user_org_ids })
          .where("seasons.registration_start_at <= ? AND seasons.registration_end_at >= ?", Time.current, Time.current)
          .includes(season: { activity_type: :organization })
      end

      def existing_registrations
        @existing_registrations ||= Registration
          .where(user_id: participant_ids, league_id: open_leagues.map(&:id))
          .where.not(status: [:canceled, :not_selected])
          .pluck(:league_id, :user_id)
          .to_set
      end

      def open_leagues_data
        open_leagues.filter_map do |league|
          eligible = eligible_members(league)
          next if eligible.empty?

          season = league.season
          activity_type = season.activity_type

          {
            id: league.id,
            name: league.name.presence || league.auto_generated_name,
            season: { id: season.id, name: season.name },
            activityType: { id: activity_type.id, name: activity_type.name },
            organization: { id: activity_type.organization.id, name: activity_type.organization.name },
            registrationEndAt: season.registration_end_at,
            full: league.full?,
            eligibleMembers: eligible.map { |u| compact_user(u) }
          }
        end
      end

      def eligible_members(league)
        participants.values.select do |user|
          !existing_registrations.include?([league.id, user.id]) && league_eligible?(league, user)
        end
      end

      def league_eligible?(league, user)
        return false if league.gender.present? && league.gender != user.gender

        if league.min_grade.present? || league.max_grade.present?
          return false if user.grade_level.nil?
          return false if league.min_grade.present? && user.grade_level < league.min_grade
          return false if league.max_grade.present? && user.grade_level > league.max_grade
        end

        if league.min_age.present? || league.max_age.present?
          return false if user.date_of_birth.nil?
          age = age_on(user.date_of_birth, league.age_cutoff_date || Date.current)
          return false if league.min_age.present? && age < league.min_age
          return false if league.max_age.present? && age > league.max_age
        end

        true
      end

      def age_on(dob, date)
        age = date.year - dob.year
        age -= 1 if date < dob + age.years
        age
      end

      def compact_user(user)
        { id: user.id, fullName: user.full_name, gradeLevel: user.grade_level }
      end
    end
  end
end
