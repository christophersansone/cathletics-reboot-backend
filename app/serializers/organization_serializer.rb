class OrganizationSerializer < BaseSerializer
  attributes :name, :slug

  has_many :organization_memberships
  has_many :activity_types
end
