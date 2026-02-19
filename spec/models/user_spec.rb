require "rails_helper"

RSpec.describe User do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:user)).to be_valid
    end

    it "requires first_name" do
      expect(build(:user, first_name: nil)).not_to be_valid
    end

    it "requires last_name" do
      expect(build(:user, last_name: nil)).not_to be_valid
    end

    it "enforces unique email among non-deleted users" do
      create(:user, email: "test@example.com")
      expect(build(:user, email: "test@example.com")).not_to be_valid
    end

    it "allows duplicate email when original is soft-deleted" do
      user = create(:user, email: "test@example.com")
      user.mark_as_deleted!
      expect(build(:user, email: "test@example.com")).to be_valid
    end

    it "allows blank email (children)" do
      expect(build(:user, :child)).to be_valid
    end
  end

  describe "enums" do
    it { expect(build(:user, gender: :male)).to be_male }
    it { expect(build(:user, gender: :female)).to be_female }
  end

  describe "#full_name" do
    it "returns first and last name" do
      user = build(:user, first_name: "Tom", last_name: "Smith")
      expect(user.full_name).to eq("Tom Smith")
    end
  end

  describe "#display_name" do
    it "returns nickname when present" do
      user = build(:user, first_name: "Thomas", nickname: "Tom")
      expect(user.display_name).to eq("Tom")
    end

    it "falls back to first_name" do
      user = build(:user, first_name: "Thomas", nickname: nil)
      expect(user.display_name).to eq("Thomas")
    end
  end

  describe "#child_in_any_family?" do
    it "returns true when user has a child family membership" do
      membership = create(:family_membership, :child)
      expect(membership.user.child_in_any_family?).to be true
    end

    it "returns false when user is a parent" do
      membership = create(:family_membership, role: :parent)
      expect(membership.user.child_in_any_family?).to be false
    end
  end

  describe "soft delete" do
    it "soft deletes instead of destroying" do
      user = create(:user)
      user.mark_as_deleted!
      expect(user.deleted?).to be true
      expect(User.count).to eq(0)
      expect(User.with_deleted.count).to eq(1)
    end
  end

  describe "associations" do
    it "has many family_memberships" do
      user = create(:user)
      family = create(:family)
      create(:family_membership, user: user, family: family, role: :parent)
      expect(user.family_memberships.count).to eq(1)
    end

    it "has many organizations through organization_memberships" do
      user = create(:user)
      org = create(:organization)
      create(:organization_membership, user: user, organization: org)
      expect(user.organizations).to include(org)
    end
  end
end
