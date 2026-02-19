FactoryBot.define do
  factory :family do
    name { "The #{Faker::Name.last_name} Family" }
  end
end
