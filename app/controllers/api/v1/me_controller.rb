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
        params.require(:data).require(:attributes).permit(
          :first_name, :last_name, :email, :nickname
        )
      end
    end
  end
end
