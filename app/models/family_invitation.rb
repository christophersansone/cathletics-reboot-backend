class FamilyInvitation < ApplicationRecord
  include SoftDeletable

  enum :role, { parent: 0, guardian: 1, viewer: 2 }

  belongs_to :family
  belongs_to :created_by, class_name: "User"

  validates :role, presence: true
  validates :token, uniqueness: { conditions: -> { where(deleted_at: nil) } }, if: :token?

  before_create :generate_token

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(16)
  end
end
