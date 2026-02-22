class TeamMembershipSerializer < BaseSerializer
  attributes :role

  belongs_to :team
  belongs_to :user
end
