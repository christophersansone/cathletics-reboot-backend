class FamilySerializer < BaseSerializer
  attributes :name

  has_many :family_memberships
end
