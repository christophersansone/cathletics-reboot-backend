class RegistrationSerializer < BaseSerializer
  attributes :status

  belongs_to :league
  belongs_to :user
  belongs_to :registered_by
end
