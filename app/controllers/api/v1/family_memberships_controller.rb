module Api
  module V1
    class FamilyMembershipsController < BaseController
      before_action :set_family
      before_action :set_family_membership, only: [:show, :update, :destroy]

      def index
        authorize! :read, @family
        render_paginated @family.family_memberships, **render_params
      end

      def show
        authorize! :read, @family_membership
        render_model @family_membership, **render_params
      end

      def create
        membership = @family.family_memberships.new(create_params)
        authorize! :create, membership

        if membership.save
          render_created_model membership, **render_params
        else
          render_errors membership
        end
      end

      def update
        authorize! :update, @family_membership

        if @family_membership.update(update_params)
          render_model @family_membership, **render_params
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

      def create_params
        json_api_attributes(:role).merge(json_api_relationships(:user))
      end

      def update_params
        json_api_attributes(:role)
      end

      def render_params
        { included: [ :family, :user ] }
      end
    end
  end
end
