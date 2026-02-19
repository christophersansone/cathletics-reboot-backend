FactoryBot.define do
  factory :registration do
    league
    user { association :user, :child }
    registered_by { association :user }
    status { :pending }
  end
end
