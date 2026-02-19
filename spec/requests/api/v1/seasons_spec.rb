require "rails_helper"

RSpec.describe "Api::V1::Seasons" do
  let(:admin) { create(:user) }
  let(:organization) { create(:organization) }
  let(:activity_type) { create(:activity_type, organization: organization) }
  let!(:season) { create(:season, activity_type: activity_type) }

  before do
    create(:organization_membership, :admin, user: admin, organization: organization)
  end

  describe "GET /api/v1/organizations/:slug/activity_types/:id/seasons" do
    it "returns seasons for the activity type" do
      get "/api/v1/organizations/#{organization.slug}/activity_types/#{activity_type.id}/seasons",
        headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(parsed_body["data"].length).to eq(1)
    end
  end

  describe "POST /api/v1/organizations/:slug/activity_types/:id/seasons" do
    let(:params) do
      {
        data: {
          attributes: {
            name: "Spring 2027",
            start_date: "2027-03-01",
            end_date: "2027-05-31",
            registration_start_at: "2027-01-15T08:00:00Z",
            registration_end_at: "2027-02-28T23:59:59Z"
          }
        }
      }
    end

    it "creates a season" do
      expect {
        post "/api/v1/organizations/#{organization.slug}/activity_types/#{activity_type.id}/seasons",
          params: params,
          headers: auth_headers_for(admin)
      }.to change(Season, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  private

  def parsed_body
    JSON.parse(response.body)
  end
end
