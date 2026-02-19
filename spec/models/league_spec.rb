require "rails_helper"

RSpec.describe League do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:league)).to be_valid
    end

    it "allows nil gender (co-ed)" do
      expect(build(:league, :coed)).to be_valid
    end

    it "allows nil grade constraints" do
      expect(build(:league, min_grade: nil, max_grade: nil)).to be_valid
    end

    it "allows age-based constraints" do
      expect(build(:league, :age_based)).to be_valid
    end
  end

  describe "#full?" do
    it "returns false when no capacity set" do
      league = build(:league, capacity: nil)
      expect(league.full?).to be false
    end

    it "returns false when under capacity" do
      league = create(:league, :with_capacity)
      create(:registration, league: league)
      expect(league.full?).to be false
    end

    it "returns true when at capacity" do
      league = create(:league, capacity: 1)
      create(:registration, league: league)
      expect(league.full?).to be true
    end
  end

  describe "#auto_generated_name" do
    let(:organization) { create(:organization) }

    it "builds name from grade range and gender" do
      activity_type = create(:activity_type, name: "Football", organization: organization)
      season = create(:season, activity_type: activity_type)
      league = create(:league, season: season, min_grade: 5, max_grade: 6, gender: :male)
      expect(league.auto_generated_name).to eq("5th-6th Male Football")
    end

    it "handles single grade" do
      activity_type = create(:activity_type, name: "Basketball", organization: organization)
      season = create(:season, activity_type: activity_type)
      league = create(:league, season: season, min_grade: 3, max_grade: 3, gender: :female)
      expect(league.auto_generated_name).to eq("3rd Female Basketball")
    end

    it "handles kindergarten and pre-k" do
      activity_type = create(:activity_type, name: "Soccer", organization: organization)
      season = create(:season, activity_type: activity_type)
      league = create(:league, season: season, min_grade: -1, max_grade: 0, gender: nil)
      expect(league.auto_generated_name).to eq("Pre-K-K Soccer")
    end

    it "handles age-based leagues" do
      activity_type = create(:activity_type, name: "Choir", organization: organization)
      season = create(:season, activity_type: activity_type)
      league = create(:league, season: season, min_grade: nil, max_grade: nil, min_age: 8, max_age: 10, age_cutoff_date: Date.new(2026, 9, 1), gender: nil)
      expect(league.auto_generated_name).to eq("Ages 8-10 Choir")
    end
  end
end
