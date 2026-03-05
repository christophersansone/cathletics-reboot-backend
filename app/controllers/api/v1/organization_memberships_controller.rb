module Api
  module V1
    class OrganizationMembershipsController < BaseController
      before_action :set_organization_membership, only: [:show, :update, :destroy]

      def index
        memberships = current_organization.organization_memberships.includes(:user)
        memberships = filter_by_user(memberships)
        memberships = filter_by_search(memberships)
        authorize! :read_members, current_organization
        render_paginated memberships, **render_params
      end

      def show
        authorize! :read, @organization_membership
        render_model @organization_membership, **render_params
      end

      def create
        membership = current_organization.organization_memberships.new(create_params)
        authorize! :create, membership

        if membership.save
          render_created_model membership, **render_params
        else
          render_errors membership
        end
      end

      def update
        authorize! :update, @organization_membership

        if @organization_membership.update(update_params)
          render_model @organization_membership, **render_params
        else
          render_errors @organization_membership
        end
      end

      def destroy
        authorize! :destroy, @organization_membership
        @organization_membership.mark_as_deleted!
        head :no_content
      end

      private

      def set_organization_membership
        @organization_membership = current_organization.organization_memberships.find(params[:id])
      end

      def filter_by_user(scope)
        return scope unless params[:user_id].present?

        scope.where(user_id: params[:user_id])
      end

      def filter_by_search(scope)
        return scope unless params[:q].present?

        q = "%#{params[:q]}%"
        scope.joins(:user).where(
          "users.first_name ILIKE :q OR users.last_name ILIKE :q OR CONCAT(users.first_name, ' ', users.last_name) ILIKE :q",
          q: q
        )
      end

      def create_params
        json_api_attributes(:role).merge(json_api_relationships(:user))
      end

      def update_params
        json_api_attributes(:role)
      end

      def render_params
        { included: [:organization, :user] }
      end
    end
  end
end
