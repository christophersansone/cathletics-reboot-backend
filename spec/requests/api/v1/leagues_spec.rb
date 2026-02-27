require "rails_helper"

RSpec.describe "Api::V1::Leagues" do
  let(:admin) { create(:user) }
  let(:organization) { create(:organization) }
  let(:activity_type) { create(:activity_type, organization: organization) }
  let(:season) { create(:season, activity_type: activity_type) }
  let!(:league) { create(:league, season: season) }

  before do
    create(:organization_membership, :admin, user: admin, organization: organization)
  end

  let(:base_path) { "/api/v1/activity_types/#{activity_type.id}/seasons/#{season.id}/leagues" }

  describe "GET .../seasons/:season_id/leagues" do
    it "returns leagues for the season" do
      get base_path, headers: auth_headers_for(admin, organization: organization)

      expect(response).to have_http_status(:ok)
      expect(parsed_body["data"].length).to eq(1)
    end
  end

  describe "POST .../seasons/:season_id/leagues" do
    let(:params) do
      {
        data: {
          attributes: {
            name: "3rd-4th Grade Girls Basketball",
            gender: "female",
            min_grade: 3,
            max_grade: 4,
            capacity: 25
          }
        }
      }
    end

    it "creates a league" do
      expect {
        post base_path, params: params, headers: auth_headers_for(admin, organization: organization)
      }.to change(League, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  private

  def parsed_body
    JSON.parse(response.body)
  end
end
