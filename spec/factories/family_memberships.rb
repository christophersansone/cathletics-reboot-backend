FactoryBot.define do
  factory :family_membership do
    family
    user
    role { :parent }

    trait :child do
      role { :child }
      user { association :user, :child }
    end

    trait :guardian do
      role { :guardian }
    end
  end
end
