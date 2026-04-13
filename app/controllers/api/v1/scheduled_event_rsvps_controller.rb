# frozen_string_literal: true

module Api
  module V1
    class ScheduledEventRsvpsController < BaseController
      before_action :set_scheduled_event, only: [:index]
      before_action :set_rsvp, only: [:show, :update, :destroy]

      def index
        authorize! :read, @scheduled_event
        relation = @scheduled_event.scheduled_event_rsvps
        if params[:occurrence_start_at].present?
          occurrence_time = Time.zone.parse(params[:occurrence_start_at])
          relation = relation.where(occurrence_start_at: occurrence_time)
        end
        render_paginated relation, **render_params
      end

      def show
        authorize! :read, @rsvp
        render_model @rsvp, **render_params
      end

      def create
        rsvp = ScheduledEventRsvp.new(create_params)
        rsvp.responded_by = current_user
        authorize! :create, rsvp

        if rsvp.save
          render_created_model rsvp, **render_params
        else
          render_errors rsvp
        end
      end

      def update
        authorize! :update, @rsvp

        if @rsvp.update(update_params)
          render_model @rsvp, **render_params
        else
          render_errors @rsvp
        end
      end

      def destroy
        authorize! :destroy, @rsvp
        @rsvp.mark_as_deleted!
        head :no_content
      end

      private

      def set_scheduled_event
        @scheduled_event = ScheduledEvent.find(params[:scheduled_event_id])
      end

      def set_rsvp
        @rsvp = ScheduledEventRsvp.find(params[:id])
      end

      def create_params
        json_api_attributes(:response, :occurrence_start_at, :note)
          .merge(json_api_relationships(:scheduled_event, :user))
      end

      def update_params
        json_api_attributes(:response, :note)
      end

      def render_params
        { included: [:user, :responded_by, :scheduled_event] }
      end
    end
  end
end
