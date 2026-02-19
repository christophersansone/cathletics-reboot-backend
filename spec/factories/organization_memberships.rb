FactoryBot.define do
  factory :organization_membership do
    organization
    user
    role { :member }

    trait :admin do
      role { :admin }
    end
  end
end
