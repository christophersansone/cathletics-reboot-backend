FactoryBot.define do
  factory :league do
    season
    name { "#{rand(3..6).ordinalize}-#{rand(7..8).ordinalize} Grade League" }
    gender { :male }
    min_grade { 5 }
    max_grade { 6 }

    trait :coed do
      gender { nil }
    end

    trait :age_based do
      min_grade { nil }
      max_grade { nil }
      min_age { 8 }
      max_age { 10 }
      age_cutoff_date { Date.new(Date.current.year, 9, 1) }
    end

    trait :with_capacity do
      capacity { 30 }
    end
  end
end
