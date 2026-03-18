# frozen_string_literal: true

FactoryBot.define do
  factory :scheduled_event do
    association :schedulable, factory: :team
    title { "Practice" }
    start_at { 1.day.from_now.change(hour: 19, min: 0) }
    end_at { 1.day.from_now.change(hour: 20, min: 30) }
    all_day { false }
  end
end
