class OrganizationMembershipSerializer < BaseSerializer
  attributes :role

  belongs_to :organization
  belongs_to :user
end
