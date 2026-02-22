module Api
  module V1
    class OrganizationMembershipsController < BaseController
      before_action :set_organization_membership, only: [:show, :update, :destroy]

      def index
        memberships = if current_organization
          current_organization.organization_memberships
        else
          current_user.organization_memberships.includes(:organization)
        end
        render_models memberships
      end

      def show
        render_model @organization_membership
      end

      def create
        membership = current_organization.organization_memberships.new(organization_membership_params)
        authorize! :create, membership

        if membership.save
          render_model membership, status: :created
        else
          render_errors membership
        end
      end

      def update
        authorize! :update, @organization_membership

        if @organization_membership.update(organization_membership_params)
          render_model @organization_membership
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

      def organization_membership_params
        params.require(:data).require(:attributes).permit(:user_id, :role)
      end
    end
  end
end
