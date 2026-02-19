class Organization < ApplicationRecord
  include SoftDeletable

  has_many :organization_memberships, dependent: :destroy
  has_many :members, through: :organization_memberships, source: :user
  has_many :activity_types, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true,
                   uniqueness: { conditions: -> { where(deleted_at: nil) } },
                   format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: "must be lowercase alphanumeric with hyphens" }

  before_validation :generate_slug, on: :create, if: -> { slug.blank? }

  private

  def generate_slug
    self.slug = name&.parameterize
  end
end
