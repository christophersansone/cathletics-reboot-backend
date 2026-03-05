module Api
  module V1
    class FamiliesController < BaseController
      before_action :set_family, only: [:show, :update, :destroy]

      def index
        families = org_scoped_families
        families = filter_by_user(families)
        families = filter_by_search(families)
        render_paginated families, **render_params
      end

      def show
        authorize! :read, @family
        render_model @family, **render_params
      end

      def create
        family = Family.new(family_params)

        if family.save
          family.family_memberships.create!(user: current_user, role: :parent)
          render_created_model family, **render_params
        else
          render_errors family
        end
      end

      def update
        authorize! :update, @family

        if @family.update(family_params)
          render_model @family, **render_params
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

      def org_scoped_families
        member_ids = current_organization.members.select(:id)
        Family.where(
          id: FamilyMembership.where(user_id: member_ids).where(deleted_at: nil).select(:family_id)
        )
      end

      def filter_by_user(scope)
        return scope unless params[:user_id].present?

        scope.where(
          id: FamilyMembership.where(user_id: params[:user_id]).where(deleted_at: nil).select(:family_id)
        )
      end

      def filter_by_search(scope)
        return scope unless params[:q].present?

        scope.where("families.name ILIKE ?", "%#{params[:q]}%")
      end

      def family_params
        json_api_attributes(:name)
      end

      def render_params
        { included: { family_memberships: :user } }
      end
    end
  end
end
