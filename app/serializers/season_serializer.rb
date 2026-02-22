class SeasonSerializer < BaseSerializer
  attributes :name, :start_date, :end_date,
             :registration_start_at, :registration_end_at

  attribute :registration_open do |season|
    season.registration_open?
  end

  belongs_to :activity_type
  has_many :leagues
end
