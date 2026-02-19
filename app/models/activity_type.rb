class ActivityType < ApplicationRecord
  include SoftDeletable

  belongs_to :organization

  has_many :seasons, dependent: :destroy

  validates :name, presence: true,
                   uniqueness: { scope: :organization_id, conditions: -> { where(deleted_at: nil) } }
end
