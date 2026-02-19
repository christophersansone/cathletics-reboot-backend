require "rails_helper"

RSpec.describe FamilyMembership do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:family_membership)).to be_valid
    end

    it "requires role" do
      expect(build(:family_membership, role: nil)).not_to be_valid
    end

    it "prevents duplicate user per family" do
      existing = create(:family_membership)
      duplicate = build(:family_membership, family: existing.family, user: existing.user)
      expect(duplicate).not_to be_valid
    end

    it "allows same user in different families" do
      user = create(:user)
      family1 = create(:family)
      family2 = create(:family)
      create(:family_membership, user: user, family: family1)
      expect(build(:family_membership, user: user, family: family2)).to be_valid
    end
  end

  describe "enums" do
    it { expect(build(:family_membership, role: :parent)).to be_parent }
    it { expect(build(:family_membership, role: :guardian)).to be_guardian }
    it { expect(build(:family_membership, role: :child)).to be_child }
  end
end
