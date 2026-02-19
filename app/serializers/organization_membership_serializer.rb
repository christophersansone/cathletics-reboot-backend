class OrganizationMembershipSerializer < LegendaryJsonApi::Serializer
  attributes :role

  belongs_to :organization
  belongs_to :user
end
