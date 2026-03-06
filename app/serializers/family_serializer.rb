class FamilySerializer < BaseSerializer
  attributes :name

  has_many :family_memberships, link: -> (model) { url_helpers.api_v1_family_memberships_url(family_id: model.id) }
end
