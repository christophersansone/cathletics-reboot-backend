class OrganizationSerializer < BaseSerializer
  attributes :name, :slug, :time_zone

  has_many :organization_memberships
  has_many :activity_types
end
