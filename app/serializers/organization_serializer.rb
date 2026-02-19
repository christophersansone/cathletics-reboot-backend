class OrganizationSerializer < LegendaryJsonApi::Serializer
  attributes :name, :slug

  has_many :organization_memberships
  has_many :activity_types
end
