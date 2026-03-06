class FamilySerializer < BaseSerializer
  attributes :name

  has_many :family_memberships, link: -> (model) { url_helpers.api_v1_family_memberships_url(family_id: model.id) }
  has_many :family_invitations, link: -> (model) { url_helpers.api_v1_family_invitations_url(family_id: model.id) }
end
