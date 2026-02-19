class TeamMembership < ApplicationRecord
  include SoftDeletable

  enum :role, { player: 0, coach: 1, assistant_coach: 2, manager: 3 }

  belongs_to :team
  belongs_to :user

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: [:team_id, :role], conditions: -> { where(deleted_at: nil) } }
end
