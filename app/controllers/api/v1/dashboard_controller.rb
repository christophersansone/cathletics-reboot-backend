module Api
  module V1
    class DashboardController < BaseController
      def show
        authorize! :read, current_organization

        today = Date.current

        active_seasons = Season.joins(:activity_type)
          .where(activity_types: { organization_id: current_organization.id })
          .where("start_date <= ? AND end_date >= ?", today, today)

        open_registration_count = League.joins(season: :activity_type)
          .where(activity_types: { organization_id: current_organization.id })
          .joins(:season)
          .where("seasons.registration_start_at <= ? AND seasons.registration_end_at >= ?", Time.current, Time.current)
          .count

        render json: {
          data: {
            activeSeasons: active_seasons.count,
            openRegistration: open_registration_count,
            totalMembers: current_organization.members.count,
            activeTeams: Team.joins(league: { season: :activity_type })
              .where(activity_types: { organization_id: current_organization.id })
              .where(seasons: { id: active_seasons.select(:id) })
              .count
          }
        }
      end
    end
  end
end
