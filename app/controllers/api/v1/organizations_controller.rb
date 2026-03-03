module Api
  module V1
    class OrganizationsController < BaseController
      skip_before_action :doorkeeper_authorize!, only: [:index, :show]
      before_action :set_organization, only: [:show, :update, :destroy]

      def index
        render_paginated Organization.all
      end

      def show
        render_model @organization
      end

      def create
        organization = Organization.new(organization_params)
        authorize! :create, organization

        if organization.save
          render_model organization, status: :created
        else
          render_errors organization
        end
      end

      def update
        authorize! :update, @organization

        if @organization.update(organization_params)
          render_model @organization
        else
          render_errors @organization
        end
      end

      def destroy
        authorize! :destroy, @organization
        @organization.mark_as_deleted!
        head :no_content
      end

      private

      def set_organization
        @organization = Organization.find_by(slug: params[:slug]) || Organization.find(params[:slug])
      end

      def organization_params
        json_api_attributes(:name, :slug, :time_zone)
      end
    end
  end
end
