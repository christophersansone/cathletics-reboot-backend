class Team < ApplicationRecord
  include SoftDeletable

  belongs_to :league
  has_one :season, through: :league
  has_one :activity_type, through: :season
  has_one :organization, through: :activity_type

  has_many :team_memberships, dependent: :destroy
  has_many :members, through: :team_memberships, source: :user
  has_many :players, -> { joins(:team_memberships).where(team_memberships: { role: :player }) },
           through: :team_memberships, source: :user
  has_many :coaches, -> { joins(:team_memberships).where(team_memberships: { role: [:coach, :assistant_coach] }) },
           through: :team_memberships, source: :user

  validates :name, presence: true
end
