module Api
  module V1
    class OrganizationRequiredError < StandardError; end

    class BaseController < ActionController::API
      include Doorkeeper::Helpers::Controller
      include CanCan::ControllerAdditions
      include Pagination
      include JsonApiParams

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

      rescue_from OrganizationRequiredError do |exception|
        render_jsonapi_error(
          title: "Organization required",
          detail: exception.message,
          status: :bad_request
        )
      end

      private

      def current_ability
        @current_ability ||= Ability.new(current_user, current_organization_if_present)
      end

      def current_organization_if_present
        current_organization
      rescue OrganizationRequiredError, ActiveRecord::RecordNotFound, CanCan::AccessDenied
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
        return @current_organization if defined?(@current_organization)

        header = request.headers["X-Org-Id"]

        @current_organization = if header.present?
          org = Organization.find_by(slug: header) || Organization.find(header)
          authorize_organization_membership!(org)
          org
        else
          infer_organization
        end
      end

      def infer_organization
        return nil unless current_user

        memberships = current_user.organization_memberships.includes(:organization)
        case memberships.size
        when 0 then nil
        when 1
          memberships.first.organization
        else
          raise OrganizationRequiredError, "Multiple organizations available. Specify one via the X-Org-Id header."
        end
      end

      def authorize_organization_membership!(org)
        return unless current_user

        unless current_user.organization_memberships.exists?(organization: org)
          raise CanCan::AccessDenied, "You are not a member of this organization."
        end
      end

      def current_membership
        @current_membership ||= current_organization.organization_memberships.find_by!(user: current_user)
      end
    end
  end
end
