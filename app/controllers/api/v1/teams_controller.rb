module Api
  module V1
    class TeamsController < BaseController
      before_action :set_league, only: [:index]
      before_action :set_team, only: [:show, :update, :destroy]

      def index
        authorize! :read, @league
        render_paginated @league.teams, **render_params
      end

      def show
        authorize! :read, @team
        render_model @team, **render_params
      end

      def create
        team = Team.new(team_params)
        authorize! :create, team

        if team.save
          render_created_model team, **render_params
        else
          render_errors team
        end
      end

      def update
        authorize! :update, @team

        if @team.update(team_params)
          render_model @team, **render_params
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

      def set_team
        @team = Team.find(params[:id])
      end

      def team_params
        json_api_attributes(:name).merge(json_api_relationships(:league))
      end

      def render_params
        { included: { league: { season: { activity_type: :organization } } } }
      end
    end
  end
end
