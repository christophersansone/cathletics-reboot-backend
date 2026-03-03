module Api
  module V1
    class UsersController < BaseController
      before_action :set_user, only: [:show, :update, :destroy]

      def index
        users = current_organization.members
        users = filter_by_search(users)
        users = filter_by_league_eligibility(users) if params[:league_id].present?
        render_paginated users
      end

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
        json_api_attributes(:first_name, :last_name, :email, :password, :nickname, :date_of_birth, :grade_level, :gender)
      end

      def filter_by_search(scope)
        return scope unless params[:q].present?

        q = "%#{params[:q]}%"
        scope.where("users.first_name ILIKE :q OR users.last_name ILIKE :q OR CONCAT(users.first_name, ' ', users.last_name) ILIKE :q", q: q)
      end

      def filter_by_league_eligibility(scope)
        league = League.find(params[:league_id])

        scope = scope.where(gender: league.gender) if league.gender.present?
        scope = scope.where("users.grade_level >= ?", league.min_grade) if league.min_grade.present?
        scope = scope.where("users.grade_level <= ?", league.max_grade) if league.max_grade.present?

        if league.min_age.present? || league.max_age.present?
          cutoff = league.age_cutoff_date&.to_date || Date.current
          if league.min_age.present?
            scope = scope.where("users.date_of_birth <= ?", cutoff - league.min_age.years)
          end
          if league.max_age.present?
            scope = scope.where("users.date_of_birth >= ?", cutoff - (league.max_age + 1).years + 1.day)
          end
        end

        already_registered = Registration.where(league: league).where(deleted_at: nil).select(:user_id)
        scope = scope.where.not(id: already_registered)

        scope
      end
    end
  end
end
