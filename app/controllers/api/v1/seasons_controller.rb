module Api
  module V1
    class SeasonsController < BaseController
      before_action :set_activity_type, only: [:index]
      before_action :set_season, only: [:show, :update, :destroy]

      def index
        authorize! :read, @activity_type
        render_paginated @activity_type.seasons
      end

      def show
        authorize! :read, @season
        render_model @season
      end

      def create
        season = Season.new(season_params)
        authorize! :create, season

        if season.save
          render_created_model season
        else
          render_errors season
        end
      end

      def update
        authorize! :update, @season

        if @season.update(season_params)
          render_model @season
        else
          render_errors @season
        end
      end

      def destroy
        authorize! :destroy, @season
        @season.mark_as_deleted!
        head :no_content
      end

      private

      def set_activity_type
        @activity_type = current_organization.activity_types.find(params[:activity_type_id])
      end

      def set_season
        @season = Season.find(params[:id])
      end

      def season_params
        json_api_attributes(:name, :start_date, :end_date, :registration_start_at, :registration_end_at, :time_zone).merge(json_api_relationships(:activity_type))
      end
    end
  end
end
