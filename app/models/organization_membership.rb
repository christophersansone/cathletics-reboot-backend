class OrganizationMembership < ApplicationRecord
  include SoftDeletable

  enum :role, { admin: 0, member: 1 }

  belongs_to :organization
  belongs_to :user

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :organization_id, conditions: -> { where(deleted_at: nil) } }
end
