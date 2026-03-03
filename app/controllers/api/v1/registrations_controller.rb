module Api
  module V1
    class RegistrationsController < BaseController
      before_action :set_league, only: [:index, :create]
      before_action :set_registration, only: [:show, :update, :destroy]

      def index
        render_paginated @league.registrations
      end

      def show
        authorize! :read, @registration
        render_model @registration
      end

      def create
        registration = @league.registrations.new(registration_params)
        registration.user_id ||= params.dig(:data, :relationships, :user, :data, :id)
        registration.registered_by = current_user
        authorize! :create, registration

        if registration.save
          render_model registration, status: :created
        else
          render_errors registration
        end
      end

      def update
        authorize! :update, @registration

        if @registration.update(registration_params)
          render_model @registration
        else
          render_errors @registration
        end
      end

      def destroy
        authorize! :destroy, @registration
        @registration.mark_as_deleted!
        head :no_content
      end

      private

      def set_league
        league_id = params[:league_id] ||
                    params.dig(:data, :relationships, :league, :data, :id)
        @league = League.find(league_id)
      end

      def set_registration
        @registration = Registration.find(params[:id])
      end

      def registration_params
        params.require(:data).require(:attributes).permit(:status)
      end
    end
  end
end
