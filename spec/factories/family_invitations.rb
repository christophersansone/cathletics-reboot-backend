FactoryBot.define do
  factory :family_invitation do
    family
    created_by { association :user }
    role { :parent }
  end
end
