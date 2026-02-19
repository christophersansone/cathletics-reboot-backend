module Api
  module V1
    class BaseController < ActionController::API
      include Doorkeeper::Helpers::Controller
      include CanCan::ControllerAdditions

      before_action :set_default_format
      before_action :doorkeeper_authorize!

      rescue_from CanCan::AccessDenied do |_exception|
        render_jsonapi_error(
          title: "Forbidden",
          detail: "You are not authorized to perform this action.",
          status: :forbidden
        )
      end

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        render_jsonapi_error(
          title: "Not found",
          detail: "The requested resource could not be found.",
          status: :not_found
        )
      end

      private

      def current_ability
        @current_ability ||= Ability.new(current_user, current_organization_if_present)
      end

      def current_organization_if_present
        current_organization
      rescue ActiveRecord::RecordNotFound
        nil
      end

      def set_default_format
        request.format = :json
      end

      def current_user
        @current_user ||= User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token&.resource_owner_id
      end

      def render_model(model, status: :ok, **options)
        render json: LegendaryJsonApi::Document.render_model(model, **options), status: status
      end

      def render_models(models, status: :ok, **options)
        render json: LegendaryJsonApi::Document.render_models(models, **options), status: status
      end

      def render_errors(model, status: :unprocessable_entity)
        errors = model.errors.map do |error|
          {
            status: Rack::Utils.status_code(status).to_s,
            source: { pointer: "/data/attributes/#{error.attribute}" },
            title: error.type.to_s.humanize,
            detail: error.full_message
          }
        end
        render json: { errors: errors }, status: status
      end

      def render_jsonapi_error(title:, detail:, status:)
        render json: {
          errors: [{
            status: Rack::Utils.status_code(status).to_s,
            title: title,
            detail: detail
          }]
        }, status: status
      end

      def current_organization
        @current_organization ||= if params[:organization_slug] || params[:slug]
          Organization.find_by!(slug: params[:organization_slug] || params[:slug])
        else
          derive_organization
        end
      end

      def derive_organization
        nil
      end

      def current_membership
        @current_membership ||= current_organization.organization_memberships.find_by!(user: current_user)
      end
    end
  end
end
