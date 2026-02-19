require "rails_helper"

RSpec.describe OrganizationMembership do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:organization_membership)).to be_valid
    end

    it "requires role" do
      expect(build(:organization_membership, role: nil)).not_to be_valid
    end

    it "prevents duplicate user per organization" do
      existing = create(:organization_membership)
      duplicate = build(:organization_membership, organization: existing.organization, user: existing.user)
      expect(duplicate).not_to be_valid
    end

    it "allows same user in multiple organizations" do
      user = create(:user)
      org1 = create(:organization)
      org2 = create(:organization)
      create(:organization_membership, user: user, organization: org1)
      expect(build(:organization_membership, user: user, organization: org2)).to be_valid
    end
  end

  describe "enums" do
    it { expect(build(:organization_membership, :admin)).to be_admin }
    it { expect(build(:organization_membership, role: :member)).to be_member }
  end
end
