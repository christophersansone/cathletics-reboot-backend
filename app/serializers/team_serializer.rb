class TeamSerializer < BaseSerializer
  attributes :name

  belongs_to :league
  has_many :team_memberships, link: ->(team) { url_helpers.api_v1_team_memberships_url(team_id: team.id) }
end
