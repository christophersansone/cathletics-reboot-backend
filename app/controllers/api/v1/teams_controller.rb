module Api
  module V1
    class TeamsController < BaseController
      before_action :set_league, only: [:index]
      before_action :set_team, only: [:show, :update, :destroy, :associated_members]

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

      def associated_members
        authorize! :read, @team
        relation = @team.team_memberships
          .where(user_id: current_user.team_participant_user_ids)
          .includes(:user)
        render_paginated relation, **associated_members_render_params
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

      def associated_members_render_params
        { included: [:team, :user] }
      end
    end
  end
end
