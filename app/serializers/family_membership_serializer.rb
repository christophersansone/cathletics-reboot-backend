class FamilyMembershipSerializer < BaseSerializer
  attributes :role

  belongs_to :family
  belongs_to :user
end
