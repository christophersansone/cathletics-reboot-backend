class Family < ApplicationRecord
  include SoftDeletable

  has_many :family_memberships, dependent: :destroy
  has_many :members, through: :family_memberships, source: :user
  has_many :parents, -> { joins(:family_memberships).where(family_memberships: { role: [:parent, :guardian] }) },
           through: :family_memberships, source: :user
  has_many :children, -> { joins(:family_memberships).where(family_memberships: { role: :child }) },
           through: :family_memberships, source: :user

  validates :name, presence: true

  def generate_name!
    parent_names = parents.pluck(:first_name)
    last_name = parents.pick(:last_name) || children.pick(:last_name)
    suffix = parent_names.any? ? " (#{parent_names.join('+')})" : ""
    update!(name: "The #{last_name} Family#{suffix}")
  end
end
