require "rails_helper"

RSpec.describe TeamMembership do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:team_membership)).to be_valid
    end

    it "requires role" do
      expect(build(:team_membership, role: nil)).not_to be_valid
    end

    it "prevents duplicate user+role per team" do
      existing = create(:team_membership, role: :player)
      duplicate = build(:team_membership, team: existing.team, user: existing.user, role: :player)
      expect(duplicate).not_to be_valid
    end

    it "allows same user in different roles on same team" do
      existing = create(:team_membership, role: :player)
      different_role = build(:team_membership, team: existing.team, user: existing.user, role: :coach)
      expect(different_role).to be_valid
    end
  end

  describe "enums" do
    it { expect(build(:team_membership, role: :player)).to be_player }
    it { expect(build(:team_membership, :coach)).to be_coach }
    it { expect(build(:team_membership, :assistant_coach)).to be_assistant_coach }
    it { expect(build(:team_membership, :manager)).to be_manager }
  end
end
