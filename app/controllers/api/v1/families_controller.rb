module Api
  module V1
    class FamiliesController < BaseController
      before_action :set_family, only: [:show, :update, :destroy]

      def index
        families = base_scope
        families = filter_by_search(families)
        render_paginated families
      end

      def show
        authorize! :read, @family
        render_model @family
      end

      def create
        family = Family.new(family_params)

        if family.save
          family.family_memberships.create!(user: current_user, role: :parent)
          render_created_model family
        else
          render_errors family
        end
      end

      def update
        authorize! :update, @family

        if @family.update(family_params)
          render_model @family
        else
          render_errors @family
        end
      end

      def destroy
        authorize! :destroy, @family
        @family.mark_as_deleted!
        head :no_content
      end

      private

      def set_family
        @family = Family.find(params[:id])
      end

      def base_scope
        if params[:user_id].present?
          user_scoped_families
        else
          org_scoped_families
        end
      end

      def user_scoped_families
        target_user = User.find(params[:user_id])
        authorize! :read, target_user
        Family.joins(:family_memberships).merge(FamilyMembership.where(user_id: target_user.id)).distinct
      end

      def org_scoped_families
        authorize! :read_members, current_organization
        Family.joins(family_memberships: { user: :organization_memberships }).where(organization_memberships: { organization_id: current_organization.id }).distinct
      end

      def filter_by_search(scope)
        return scope unless params[:q].present?

        scope.where("families.name ILIKE ?", "%#{params[:q]}%")
      end

      def family_params
        json_api_attributes(:name)
      end

    end
  end
end
