module Api
  module V1
    class ChildrenController < BaseController
      def create
        family = Family.find(family_id)
        authorize! :manage, FamilyMembership.new(family: family)

        child = nil
        ActiveRecord::Base.transaction do
          child = User.create!(child_params)
          family.family_memberships.create!(user: child, role: :child)
        end

        render_created_model child, included: [:family_memberships]
      end

      private

      def family_id
        params[:family_id] || json_api_relationships(:family)[:family_id]
      end

      def child_params
        json_api_attributes(:first_name, :last_name, :date_of_birth, :grade_level, :gender)
      end
    end
  end
end
