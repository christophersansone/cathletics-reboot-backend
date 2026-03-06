module Api
  module V1
    class SignupController < BaseController
      skip_before_action :doorkeeper_authorize!

      def create
        user = User.new(signup_params)

        if user.save
          render_created_model user
        else
          render_errors user
        end
      end

      private

      def signup_params
        json_api_attributes(:first_name, :last_name, :email, :password)
      end
    end
  end
end
