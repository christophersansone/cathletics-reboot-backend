FactoryBot.define do
  factory :season do
    activity_type
    name { "#{%w[Fall Winter Spring Summer].sample} #{Date.current.year}" }
    start_date { 2.months.from_now.to_date }
    end_date { 5.months.from_now.to_date }
    registration_start_at { 1.month.ago }
    registration_end_at { 1.month.from_now }
  end
end
