# frozen_string_literal: true

# Helpers for endpoints that operate on "the current user's family":
# the user themselves plus all children in families where they are a
# parent or guardian.
module FamilyParticipants
  extend ActiveSupport::Concern

  private

  def participant_ids
    @participant_ids ||= begin
      family_ids = current_user.family_memberships.where(role: [:parent, :guardian]).pluck(:family_id)
      child_ids = FamilyMembership.where(family_id: family_ids, role: :child).pluck(:user_id)
      (child_ids + [current_user.id]).uniq
    end
  end

  def participants
    @participants ||= User.where(id: participant_ids).index_by(&:id)
  end

  def compact_user(user)
    { id: user.id, fullName: user.full_name, gradeLevel: user.grade_level }
  end
end
