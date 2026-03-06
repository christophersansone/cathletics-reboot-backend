class FamilyInvitationSerializer < BaseSerializer
  attributes :role, :token, :expires_at, :created_at

  belongs_to :family
  belongs_to :created_by, serializer: UserSerializer
end
