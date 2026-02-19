require "rails_helper"

RSpec.describe Season do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:season)).to be_valid
    end

    it "requires name" do
      expect(build(:season, name: nil)).not_to be_valid
    end

    it "enforces unique name per activity type" do
      activity_type = create(:activity_type)
      create(:season, activity_type: activity_type, name: "Fall 2026")
      expect(build(:season, activity_type: activity_type, name: "Fall 2026")).not_to be_valid
    end
  end

  describe "#registration_open?" do
    it "returns true when within registration window" do
      season = build(:season,
        registration_start_at: 1.day.ago,
        registration_end_at: 1.day.from_now)
      expect(season.registration_open?).to be true
    end

    it "returns false before registration opens" do
      season = build(:season,
        registration_start_at: 1.day.from_now,
        registration_end_at: 2.days.from_now)
      expect(season.registration_open?).to be false
    end

    it "returns false after registration closes" do
      season = build(:season,
        registration_start_at: 2.days.ago,
        registration_end_at: 1.day.ago)
      expect(season.registration_open?).to be false
    end

    it "returns false when dates are nil" do
      season = build(:season, registration_start_at: nil, registration_end_at: nil)
      expect(season.registration_open?).to be false
    end
  end
end
