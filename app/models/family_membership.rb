class FamilyMembership < ApplicationRecord
  include SoftDeletable

  enum :role, { parent: 0, guardian: 1, child: 2 }

  belongs_to :family
  belongs_to :user

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :family_id, conditions: -> { where(deleted_at: nil) } }
end
