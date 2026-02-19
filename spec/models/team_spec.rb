require "rails_helper"

RSpec.describe Team do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:team)).to be_valid
    end

    it "requires name" do
      expect(build(:team, name: nil)).not_to be_valid
    end
  end

  describe "associations" do
    it "has players and coaches through team_memberships" do
      team = create(:team)
      player = create(:user, :child)
      coach = create(:user)
      create(:team_membership, team: team, user: player, role: :player)
      create(:team_membership, team: team, user: coach, role: :coach)

      expect(team.players).to include(player)
      expect(team.coaches).to include(coach)
      expect(team.members.count).to eq(2)
    end
  end

  describe "delegation" do
    it "reaches the organization through league -> season -> activity_type" do
      org = create(:organization)
      activity_type = create(:activity_type, organization: org)
      season = create(:season, activity_type: activity_type)
      league = create(:league, season: season)
      team = create(:team, league: league)

      expect(team.organization).to eq(org)
    end
  end
end
