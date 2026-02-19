module Api
  module V1
    class UsersController < BaseController
      before_action :set_user, only: [:show, :update, :destroy]

      def show
        authorize! :read, @user
        render_model @user
      end

      def update
        authorize! :update, @user

        if @user.update(user_params)
          render_model @user
        else
          render_errors @user
        end
      end

      def destroy
        authorize! :destroy, @user
        @user.mark_as_deleted!
        head :no_content
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        params.require(:data).require(:attributes).permit(
          :first_name, :last_name, :email, :password, :nickname,
          :date_of_birth, :grade_level, :gender
        )
      end
    end
  end
end
