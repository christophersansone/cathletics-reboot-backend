module Api
  module V1
    class SeasonsController < BaseController
      before_action :set_activity_type, only: [:index, :create]
      before_action :set_season, only: [:show, :update, :destroy]

      def index
        render_paginated @activity_type.seasons
      end

      def show
        render_model @season
      end

      def create
        season = @activity_type.seasons.new(season_params)
        authorize! :create, season

        if season.save
          render_model season, status: :created
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
        at_id = params[:activity_type_id] || json_api_relationships(:activity_type)[:activity_type_id]
        @activity_type = current_organization.activity_types.find(at_id)
      end

      def set_season
        @season = Season.find(params[:id])
      end

      def season_params
        json_api_attributes(:name, :start_date, :end_date, :registration_start_at, :registration_end_at, :time_zone)
      end
    end
  end
end
