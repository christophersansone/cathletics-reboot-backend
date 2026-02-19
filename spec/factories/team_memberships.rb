FactoryBot.define do
  factory :team_membership do
    team
    user
    role { :player }

    trait :coach do
      role { :coach }
    end

    trait :assistant_coach do
      role { :assistant_coach }
    end

    trait :manager do
      role { :manager }
    end
  end
end
