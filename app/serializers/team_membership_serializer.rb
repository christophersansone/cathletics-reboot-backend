class TeamMembershipSerializer < BaseSerializer
  attributes :role, :uniform_number, :position

  belongs_to :team
  belongs_to :user
end
