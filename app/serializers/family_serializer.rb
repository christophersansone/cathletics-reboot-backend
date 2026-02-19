class FamilySerializer < LegendaryJsonApi::Serializer
  attributes :name

  has_many :family_memberships
end
