module Api
  module V1
    class MeController < BaseController
      def show
        render_model current_user
      end

      def update
        if current_user.update(me_params)
          render_model current_user
        else
          render_errors current_user
        end
      end

      private

      def me_params
        json_api_attributes(:first_name, :last_name, :nickname)
      end
    end
  end
end
