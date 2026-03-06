module Api
  module V1
    class FamilyInvitationsController < BaseController
      skip_before_action :doorkeeper_authorize!, only: [:show]
      before_action :set_invitation, only: [:show]

      def index
        family = Family.find(params[:family_id])
        authorize! :manage, FamilyInvitation.new(family: family)
        render_paginated family.family_invitations, **render_params
      end

      def show
        render_model @invitation, **render_params
      end

      def create
        invitation = FamilyInvitation.new(create_params.merge(created_by: current_user))
        authorize! :create, invitation

        if invitation.save
          render_created_model invitation, **render_params
        else
          render_errors invitation
        end
      end

      def destroy
        invitation = FamilyInvitation.find(params[:id])
        authorize! :destroy, invitation
        invitation.mark_as_deleted!
        head :no_content
      end

      def accept
        invitation = FamilyInvitation.find_by!(token: params[:id])
        existing = invitation.family.family_memberships.find_by(user: current_user)

        if existing
          render_model existing, included: [:family, :user]
        else
          membership = invitation.family.family_memberships.create!(
            user: current_user,
            role: invitation.role
          )
          render_created_model membership, included: [:family, :user]
        end
      end

      private

      def set_invitation
        @invitation = FamilyInvitation.find_by!(token: params[:id])
      end

      def create_params
        json_api_attributes(:role).merge(json_api_relationships(:family))
      end

      def render_params
        { included: [:family, :created_by] }
      end
    end
  end
end
