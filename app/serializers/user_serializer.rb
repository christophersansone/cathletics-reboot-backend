class UserSerializer < BaseSerializer
  attributes :first_name, :last_name, :email, :nickname,
             :date_of_birth, :grade_level, :gender

  attribute :full_name do |user|
    user.full_name
  end

  attribute :display_name do |user|
    user.display_name
  end

  has_many :family_memberships
  has_many :organization_memberships, link: ->(user) { url_helpers.api_v1_organization_memberships_url(user_id: user.id) }
end
