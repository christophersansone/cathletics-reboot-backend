module Api
  module V1
    class ActivityTypesController < BaseController
      before_action :set_activity_type, only: [:show, :update, :destroy]

      def index
        render_paginated current_organization.activity_types
      end

      def show
        authorize! :read, @activity_type
        render_model @activity_type
      end

      def create
        activity_type = current_organization.activity_types.new(activity_type_params)
        authorize! :create, activity_type

        if activity_type.save
          render_created_model activity_type
        else
          render_errors activity_type
        end
      end

      def update
        authorize! :update, @activity_type

        if @activity_type.update(activity_type_params)
          render_model @activity_type
        else
          render_errors @activity_type
        end
      end

      def destroy
        authorize! :destroy, @activity_type
        @activity_type.mark_as_deleted!
        head :no_content
      end

      private

      def set_activity_type
        @activity_type = ActivityType.find(params[:id])
      end

      def activity_type_params
        json_api_attributes(:name, :description)
      end
    end
  end
end
