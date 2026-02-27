module Api
  module V1
    class SeasonsController < BaseController
      before_action :set_activity_type
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
        @activity_type = current_organization.activity_types.find(params[:activity_type_id])
      end

      def set_season
        @season = @activity_type.seasons.find(params[:id])
      end

      def season_params
        params.require(:data).require(:attributes).permit(
          :name, :start_date, :end_date,
          :registration_start_at, :registration_end_at
        )
      end
    end
  end
end
