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
      get "/api/v1/leagues/#{league.id}/teams", headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(parsed_body["data"].length).to eq(1)
    end
  end

  describe "POST /api/v1/leagues/:league_id/teams" do
    it "creates a team" do
      expect {
        post "/api/v1/leagues/#{league.id}/teams",
          params: { data: { attributes: { name: "B Team" } } },
          headers: auth_headers_for(admin)
      }.to change(Team, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  private

  def parsed_body
    JSON.parse(response.body)
  end
end
