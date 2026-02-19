FactoryBot.define do
  factory :activity_type do
    organization
    name { %w[Football Basketball Volleyball Choir Band Soccer Baseball].sample }
    description { Faker::Lorem.sentence }
  end
end
