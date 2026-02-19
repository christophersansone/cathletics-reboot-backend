FactoryBot.define do
  factory :organization do
    name { "St. #{Faker::Name.first_name}'s #{%w[Academy School Parish].sample}" }
    slug { name.parameterize }
  end
end
