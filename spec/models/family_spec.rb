require "rails_helper"

RSpec.describe Family do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:family)).to be_valid
    end

    it "requires name" do
      expect(build(:family, name: nil)).not_to be_valid
    end
  end

  describe "#generate_name!" do
    it "generates a name from parent names" do
      family = create(:family, name: "Placeholder")
      tom = create(:user, first_name: "Tom", last_name: "Smith")
      katie = create(:user, first_name: "Katie", last_name: "Smith")
      create(:family_membership, family: family, user: tom, role: :parent)
      create(:family_membership, family: family, user: katie, role: :parent)

      family.generate_name!
      expect(family.name).to eq("The Smith Family (Tom+Katie)")
    end

    it "works with a single parent" do
      family = create(:family, name: "Placeholder")
      dave = create(:user, first_name: "Dave", last_name: "Martinez")
      create(:family_membership, family: family, user: dave, role: :parent)

      family.generate_name!
      expect(family.name).to eq("The Martinez Family (Dave)")
    end
  end

  describe "associations" do
    it "returns parents and children separately" do
      family = create(:family)
      parent = create(:user)
      child = create(:user, :child)
      create(:family_membership, family: family, user: parent, role: :parent)
      create(:family_membership, family: family, user: child, role: :child)

      expect(family.parents).to include(parent)
      expect(family.children).to include(child)
      expect(family.members.count).to eq(2)
    end
  end
end
