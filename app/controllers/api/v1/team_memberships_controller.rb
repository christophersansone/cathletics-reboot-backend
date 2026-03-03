module Api
  module V1
    class TeamMembershipsController < BaseController
      before_action :set_team, only: [:index, :create]
      before_action :set_team_membership, only: [:show, :update, :destroy]

      def index
        render_paginated @team.team_memberships
      end

      def show
        render_model @team_membership
      end

      def create
        membership = @team.team_memberships.new(create_params)
        authorize! :create, membership

        if membership.save
          render_model membership, status: :created
        else
          render_errors membership
        end
      end

      def update
        authorize! :update, @team_membership

        if @team_membership.update(update_params)
          render_model @team_membership
        else
          render_errors @team_membership
        end
      end

      def destroy
        authorize! :destroy, @team_membership
        @team_membership.mark_as_deleted!
        head :no_content
      end

      private

      def set_team
        team_id = params[:team_id] || json_api_relationships(:team)[:team_id]
        @team = Team.find(team_id)
      end

      def set_team_membership
        @team_membership = TeamMembership.find(params[:id])
      end

      def create_params
        json_api_attributes(:role).merge(json_api_relationships(:user))
      end

      def update_params
        json_api_attributes(:role)
      end
    end
  end
end
