module Api
  module V1
    class FamilyMembershipsController < BaseController
      before_action :set_family
      before_action :set_family_membership, only: [:show, :update, :destroy]

      def index
        authorize! :read, @family
        render_paginated @family.family_memberships
      end

      def show
        authorize! :read, @family_membership
        render_model @family_membership
      end

      def create
        membership = @family.family_memberships.new(family_membership_params)
        authorize! :create, membership

        if membership.save
          render_model membership, status: :created
        else
          render_errors membership
        end
      end

      def update
        authorize! :update, @family_membership

        if @family_membership.update(family_membership_params)
          render_model @family_membership
        else
          render_errors @family_membership
        end
      end

      def destroy
        authorize! :destroy, @family_membership
        @family_membership.mark_as_deleted!
        head :no_content
      end

      private

      def set_family
        @family = Family.find(params[:family_id])
      end

      def set_family_membership
        @family_membership = @family.family_memberships.find(params[:id])
      end

      def family_membership_params
        params.require(:data).require(:attributes).permit(:user_id, :role)
      end
    end
  end
end
