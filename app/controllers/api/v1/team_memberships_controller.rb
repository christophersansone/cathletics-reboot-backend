module Api
  module V1
    class TeamMembershipsController < BaseController
      before_action :set_team
      before_action :set_team_membership, only: [:show, :update, :destroy]

      def index
        render_paginated @team.team_memberships
      end

      def show
        render_model @team_membership
      end

      def create
        membership = @team.team_memberships.new(team_membership_params)
        authorize! :create, membership

        if membership.save
          render_model membership, status: :created
        else
          render_errors membership
        end
      end

      def update
        authorize! :update, @team_membership

        if @team_membership.update(team_membership_params)
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
        @team = Team.find(params[:team_id])
      end

      def set_team_membership
        @team_membership = @team.team_memberships.find(params[:id])
      end

      def team_membership_params
        params.require(:data).require(:attributes).permit(:user_id, :role)
      end
    end
  end
end
