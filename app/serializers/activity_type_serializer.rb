class ActivityTypeSerializer < BaseSerializer
  attributes :name, :description

  belongs_to :organization
  has_many :seasons
end
