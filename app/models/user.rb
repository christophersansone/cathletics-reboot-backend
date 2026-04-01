class User < ApplicationRecord
  include SoftDeletable

  has_secure_password validations: false

  enum :gender, { male: 0, female: 1 }

  has_many :family_memberships, dependent: :destroy
  has_many :families, through: :family_memberships
  has_many :organization_memberships, dependent: :destroy
  has_many :organizations, through: :organization_memberships
  has_many :team_memberships, dependent: :destroy
  has_many :teams, through: :team_memberships
  has_many :registrations, dependent: :destroy
  has_many :submitted_registrations, class_name: "Registration", foreign_key: :registered_by_id, dependent: :destroy, inverse_of: :registered_by

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, uniqueness: { conditions: -> { where(deleted_at: nil) } }, allow_blank: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def display_name
    nickname.presence || first_name
  end

  def child_in_any_family?
    family_memberships.exists?(role: :child)
  end

  # Self plus children in families where this user is a parent or guardian (team registration / schedule context).
  def team_participant_user_ids
    family_ids = family_memberships.where(role: [:parent, :guardian]).pluck(:family_id)
    child_ids = FamilyMembership.where(family_id: family_ids, role: :child).pluck(:user_id)
    ([id] + child_ids).uniq
  end
end
