module Api
  module V1
    class TeamsController < BaseController
      before_action :set_league, only: [:index, :create]
      before_action :set_team, only: [:show, :update, :destroy]

      def index
        render_paginated @league.teams
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
        league_id = params[:league_id] ||
                    params.dig(:data, :relationships, :league, :data, :id)
        @league = League.find(league_id)
      end

      def set_team
        @team = Team.find(params[:id])
      end

      def team_params
        params.require(:data).require(:attributes).permit(:name)
      end
    end
  end
end
