class ActivityTypeSerializer < LegendaryJsonApi::Serializer
  attributes :name, :description

  belongs_to :organization
  has_many :seasons
end
