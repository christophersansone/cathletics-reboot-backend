# frozen_string_literal: true

module Api
  module V1
    class ScheduledEventsController < BaseController
      before_action :set_team, only: [:index]
      before_action :set_scheduled_event, only: [:show, :update, :destroy]

      def index
        if params[:team_id].present?
          authorize! :read, @team
          relation = @team.scheduled_events
        else
          relation = ScheduledEvent.where(schedulable_type: "Team", schedulable_id: accessible_team_ids)
        end
        render_paginated relation, **render_params
      end

      def show
        authorize! :read, @scheduled_event
        render_model @scheduled_event, **render_params
      end

      def create
        event = ScheduledEvent.new(create_params)
        authorize! :create, event

        if event.save
          render_created_model event, **render_params
        else
          render_errors event
        end
      end

      def update
        authorize! :update, @scheduled_event

        if @scheduled_event.update(update_params)
          render_model @scheduled_event, **render_params
        else
          render_errors @scheduled_event
        end
      end

      def destroy
        authorize! :destroy, @scheduled_event
        @scheduled_event.mark_as_deleted!
        head :no_content
      end

      private

      def set_team
        @team = Team.find(params[:team_id]) if params[:team_id].present?
      end

      def set_scheduled_event
        @scheduled_event = ScheduledEvent.find(params[:id])
      end

      def create_params
        arrays = json_api_raw_attributes(:exdates, :cancelled_occurrences)
        attrs = json_api_attributes(:title, :description, :start_at, :end_at, :time_zone, :all_day, :rrule, :recurs_until, :cancelled_from, :cancellation_reason)
        attrs = attrs.merge(json_api_polymorphic_relationships(:schedulable))
        arrays.merge(attrs)
      end

      def update_params
        arrays = json_api_raw_attributes(:exdates, :cancelled_occurrences)
        attrs = json_api_attributes(:title, :description, :start_at, :end_at, :time_zone, :all_day, :rrule, :recurs_until, :cancelled_from, :cancellation_reason)
        arrays.merge(attrs)
      end

      def render_params
        { included: [:schedulable] }
      end

      def accessible_team_ids
        return [] unless current_organization

        Team.joins(league: { season: { activity_type: :organization } })
            .where(activity_types: { organization_id: current_organization.id })
            .pluck(:id)
      end
    end
  end
end
