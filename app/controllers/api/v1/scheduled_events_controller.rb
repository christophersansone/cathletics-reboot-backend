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
        attrs = json_api_attributes(:title, :description, :start_at, :end_at, :time_zone, :all_day, :rrule)
        attrs = attrs.merge(schedulable_params) if schedulable_params.present?
        exdates_val = params.dig(:data, :attributes, :exdates)
        attrs[:exdates] = exdates_val if exdates_val.is_a?(Array)
        attrs
      end

      def schedulable_params
        return {} unless params.dig(:data, :relationships, :schedulable, :data).present?

        data = params.require(:data).require(:relationships).require(:schedulable).require(:data)
        type = data[:type].to_s.singularize.classify
        id = data[:id]
        return {} if type.blank? || id.blank?

        { schedulable_type: type, schedulable_id: id }
      end

      def update_params
        attrs = json_api_attributes(:title, :description, :start_at, :end_at, :time_zone, :all_day, :rrule)
        exdates_val = params.dig(:data, :attributes, :exdates)
        attrs[:exdates] = exdates_val if exdates_val.is_a?(Array)
        attrs
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
