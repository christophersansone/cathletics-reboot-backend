FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    password { "password" }
    gender { %i[male female].sample }
    date_of_birth { Faker::Date.birthday(min_age: 25, max_age: 50) }

    trait :child do
      email { nil }
      password { nil }
      date_of_birth { Faker::Date.birthday(min_age: 5, max_age: 14) }
      grade_level { rand(-1..8) }
    end
  end
end
