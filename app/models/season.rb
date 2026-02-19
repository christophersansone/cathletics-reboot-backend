class Season < ApplicationRecord
  include SoftDeletable

  belongs_to :activity_type
  has_one :organization, through: :activity_type

  has_many :leagues, dependent: :destroy

  validates :name, presence: true,
                   uniqueness: { scope: :activity_type_id, conditions: -> { where(deleted_at: nil) } }

  def registration_open?
    return false unless registration_start_at && registration_end_at

    Time.current.between?(registration_start_at, registration_end_at)
  end
end
