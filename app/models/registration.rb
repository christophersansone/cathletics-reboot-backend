class Registration < ApplicationRecord
  include SoftDeletable

  enum :status, { pending: 0, confirmed: 1, waitlisted: 2, canceled: 3, not_selected: 4 }

  belongs_to :league
  belongs_to :user
  belongs_to :registered_by, class_name: "User"

  validates :status, presence: true
  validates :user_id, uniqueness: { scope: :league_id, conditions: -> { where(deleted_at: nil) } }

  def confirm!
    update!(status: :confirmed)
  end

  def waitlist!
    update!(status: :waitlisted)
  end

  def cancel!
    update!(status: :canceled)
  end
end
