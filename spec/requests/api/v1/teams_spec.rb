require "rails_helper"

RSpec.describe "Api::V1::Teams" do
  let(:admin) { create(:user) }
  let(:organization) { create(:organization) }
  let(:activity_type) { create(:activity_type, organization: organization) }
  let(:season) { create(:season, activity_type: activity_type) }
  let(:league) { create(:league, season: season) }
  let!(:team) { create(:team, league: league) }

  before do
    create(:organization_membership, :admin, user: admin, organization: organization)
  end

  describe "GET /api/v1/leagues/:league_id/teams" do
    it "returns teams for the league" do
      get "/api/v1/leagues/#{league.id}/teams",
        headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:ok)
      expect(parsed_body["data"].length).to eq(1)
    end
  end

  describe "POST /api/v1/leagues/:league_id/teams" do
    it "creates a team" do
      expect {
        post "/api/v1/leagues/#{league.id}/teams",
          params: {
            data: {
              attributes: { name: "B Team" },
              relationships: { league: { data: { type: "leagues", id: league.id.to_s } } }
            }
          },
          headers: auth_headers_for(admin, organization: organization)
      }.to change(Team, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  describe "GET /api/v1/teams/:id/associated_members" do
    it "returns memberships for the signed-in user and represented children" do
      family = create(:family)
      parent = create(:user)
      create(:family_membership, family: family, user: parent, role: :parent)
      child_user = create(:user, :child)
      create(:family_membership, family: family, user: child_user, role: :child)
      create(:organization_membership, user: parent, organization: organization)
      membership = create(:team_membership, team: team, user: child_user, role: :player)

      get "/api/v1/teams/#{team.id}/associated_members",
        headers: auth_headers_for(parent, organization: organization)

      expect(response).to have_http_status(:ok)
      data = parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data.first["id"]).to eq(membership.id.to_s)
      included_types = (parsed_body["included"] || []).map { |r| r["type"] }
      expect(included_types).to include("user")
    end

    it "returns the coach's own membership when they are on the team" do
      coach = create(:user)
      create(:organization_membership, user: coach, organization: organization)
      coach_membership = create(:team_membership, :coach, team: team, user: coach)

      get "/api/v1/teams/#{team.id}/associated_members",
        headers: auth_headers_for(coach, organization: organization)

      expect(response).to have_http_status(:ok)
      ids = parsed_body["data"].map { |r| r["id"] }
      expect(ids).to contain_exactly(coach_membership.id.to_s)
    end

    it "returns no data when the user has org access but no represented people on the roster" do
      outsider = create(:user)
      create(:organization_membership, user: outsider, organization: organization)

      get "/api/v1/teams/#{team.id}/associated_members",
        headers: auth_headers_for(outsider, organization: organization)

      expect(response).to have_http_status(:ok)
      expect(parsed_body["data"]).to eq([])
    end

    it "returns forbidden when the user cannot read the team" do
      other_org = create(:organization)
      intruder = create(:user)
      create(:organization_membership, user: intruder, organization: other_org)

      get "/api/v1/teams/#{team.id}/associated_members",
        headers: auth_headers_for(intruder, organization: other_org)

      expect(response).to have_http_status(:forbidden)
    end
  end

  private

  def parsed_body
    JSON.parse(response.body)
  end
end
