module Api
  module V1
    class FamiliesController < BaseController
      before_action :set_family, only: [:show, :update, :destroy]

      def index
        render_paginated current_user.families
      end

      def show
        authorize! :read, @family
        render_model @family
      end

      def create
        family = Family.new(family_params)

        if family.save
          family.family_memberships.create!(user: current_user, role: :parent)
          render_model family, status: :created
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

      def family_params
        json_api_attributes(:name)
      end
    end
  end
end
