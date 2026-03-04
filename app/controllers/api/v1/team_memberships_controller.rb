module Api
  module V1
    class TeamMembershipsController < BaseController
      before_action :set_team, only: [:index]
      before_action :set_team_membership, only: [:show, :update, :destroy]

      def index
        authorize! :read, @team
        render_paginated @team.team_memberships, **render_params
      end

      def show
        authorize! :read, @team_membership
        render_model @team_membership, **render_params
      end

      def create
        membership = TeamMembership.new(create_params)
        authorize! :create, membership

        if membership.save
          render_created_model membership, **render_params
        else
          render_errors membership
        end
      end

      def update
        authorize! :update, @team_membership

        if @team_membership.update(update_params)
          render_model @team_membership, **render_params
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
        @team_membership = TeamMembership.find(params[:id])
      end

      def create_params
        json_api_attributes(:role).merge(json_api_relationships(:user, :team))
      end

      def update_params
        json_api_attributes(:role)
      end

      def render_params
        { included: [ :team, :user ] }
      end
    end
  end
end
