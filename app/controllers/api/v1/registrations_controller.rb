module Api
  module V1
    class RegistrationsController < BaseController
      before_action :set_league, only: [:index]
      before_action :set_registration, only: [:show, :update, :destroy]

      def index
        authorize! :read, @league
        render_paginated @league.registrations, **render_params
      end

      def show
        authorize! :read, @registration
        render_model @registration, **render_params
      end

      def create
        registration = Registration.new(create_params)
        registration.registered_by = current_user
        authorize! :create, registration

        if registration.save
          render_created_model registration, **render_params
        else
          render_errors registration
        end
      end

      def update
        authorize! :update, @registration

        if @registration.update(update_params)
          render_model @registration, **render_params
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
        @league = League.find(params[:league_id])
      end

      def set_registration
        @registration = Registration.find(params[:id])
      end

      def create_params
        json_api_attributes(:status).merge(json_api_relationships(:user, :league))
      end

      def update_params
        json_api_attributes(:status)
      end

      def render_params
        { included: [:user, :registered_by, :league] }
      end
    end
  end
end
