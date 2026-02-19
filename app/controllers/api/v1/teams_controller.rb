module Api
  module V1
    class TeamsController < BaseController
      before_action :set_league
      before_action :set_team, only: [:show, :update, :destroy]

      def index
        teams = @league.teams
        render_models teams
      end

      def show
        render_model @team
      end

      def create
        team = @league.teams.new(team_params)
        authorize! :create, team

        if team.save
          render_model team, status: :created
        else
          render_errors team
        end
      end

      def update
        authorize! :update, @team

        if @team.update(team_params)
          render_model @team
        else
          render_errors @team
        end
      end

      def destroy
        authorize! :destroy, @team
        @team.mark_as_deleted!
        head :no_content
      end

      private

      def set_league
        @league = League.find(params[:league_id])
      end

      def derive_organization
        @league&.organization
      end

      def set_team
        @team = @league.teams.find(params[:id])
      end

      def team_params
        params.require(:data).require(:attributes).permit(:name)
      end
    end
  end
end
