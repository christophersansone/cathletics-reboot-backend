FactoryBot.define do
  factory :team do
    league
    name { "#{%w[A B C].sample} Team" }
  end
end
