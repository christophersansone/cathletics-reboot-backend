module Api
  module V1
    class SignupController < BaseController
      skip_before_action :doorkeeper_authorize!

      def create
        user = User.new(signup_params)

        if user.save
          render_model user, status: :created
        else
          render_errors user
        end
      end

      private

      def signup_params
        params.require(:data).require(:attributes).permit(
          :first_name, :last_name, :email, :password
        )
      end
    end
  end
end
