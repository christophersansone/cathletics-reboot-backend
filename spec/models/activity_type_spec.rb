require "rails_helper"

RSpec.describe ActivityType do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:activity_type)).to be_valid
    end

    it "requires name" do
      expect(build(:activity_type, name: nil)).not_to be_valid
    end

    it "enforces unique name per organization" do
      org = create(:organization)
      create(:activity_type, organization: org, name: "Football")
      expect(build(:activity_type, organization: org, name: "Football")).not_to be_valid
    end

    it "allows same name in different organizations" do
      create(:activity_type, name: "Football")
      expect(build(:activity_type, name: "Football")).to be_valid
    end
  end

  describe "associations" do
    it "has many seasons" do
      activity_type = create(:activity_type)
      create(:season, activity_type: activity_type)
      expect(activity_type.seasons.count).to eq(1)
    end
  end
end
