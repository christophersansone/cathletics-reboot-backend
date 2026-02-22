class TeamSerializer < BaseSerializer
  attributes :name

  belongs_to :league
  has_many :team_memberships
end
