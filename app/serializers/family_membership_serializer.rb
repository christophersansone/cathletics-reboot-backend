class FamilyMembershipSerializer < LegendaryJsonApi::Serializer
  attributes :role

  belongs_to :family
  belongs_to :user
end
