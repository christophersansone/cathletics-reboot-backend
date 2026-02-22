class LeagueSerializer < BaseSerializer
  attributes :name, :gender, :min_grade, :max_grade,
             :min_age, :max_age, :age_cutoff_date, :capacity

  attribute :full do |league|
    league.full?
  end

  attribute :auto_generated_name do |league|
    league.auto_generated_name
  end

  belongs_to :season
  has_many :teams
  has_many :registrations
end
