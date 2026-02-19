class TeamMembershipSerializer < LegendaryJsonApi::Serializer
  attributes :role

  belongs_to :team
  belongs_to :user
end
