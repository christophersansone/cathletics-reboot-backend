require "rails_helper"

RSpec.describe "Api::V1::Registrations" do
  let(:organization) { create(:organization) }
  let(:activity_type) { create(:activity_type, organization: organization) }
  let(:season) { create(:season, activity_type: activity_type) }
  let(:league) { create(:league, season: season) }

  let(:parent) { create(:user) }
  let(:child) { create(:user, :child) }
  let(:family) { create(:family) }

  before do
    create(:organization_membership, user: parent, organization: organization)
    create(:family_membership, family: family, user: parent, role: :parent)
    create(:family_membership, family: family, user: child, role: :child)
  end

  describe "POST /api/v1/leagues/:league_id/registrations" do
    it "allows a parent to register their child" do
      expect {
        post "/api/v1/leagues/#{league.id}/registrations",
          params: { data: { attributes: { user_id: child.id } } },
          headers: auth_headers_for(parent)
      }.to change(Registration, :count).by(1)

      expect(response).to have_http_status(:created)
      reg = Registration.last
      expect(reg.user).to eq(child)
      expect(reg.registered_by).to eq(parent)
      expect(reg).to be_pending
    end

    it "returns 401 without authentication" do
      post "/api/v1/leagues/#{league.id}/registrations",
        params: { data: { attributes: { user_id: child.id } } }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/leagues/:league_id/registrations" do
    let(:admin) { create(:user) }

    before do
      create(:organization_membership, :admin, user: admin, organization: organization)
      create(:registration, league: league, user: child, registered_by: parent)
    end

    it "returns registrations for the league" do
      get "/api/v1/leagues/#{league.id}/registrations",
        headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(parsed_body["data"].length).to eq(1)
    end
  end

  describe "PATCH /api/v1/leagues/:league_id/registrations/:id" do
    let(:admin) { create(:user) }
    let!(:registration) { create(:registration, league: league, user: child, registered_by: parent) }

    before do
      create(:organization_membership, :admin, user: admin, organization: organization)
    end

    it "allows admin to confirm a registration" do
      patch "/api/v1/leagues/#{league.id}/registrations/#{registration.id}",
        params: { data: { attributes: { status: "confirmed" } } },
        headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(registration.reload).to be_confirmed
    end

    it "allows admin to mark as not_selected" do
      patch "/api/v1/leagues/#{league.id}/registrations/#{registration.id}",
        params: { data: { attributes: { status: "not_selected" } } },
        headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(registration.reload).to be_not_selected
    end
  end

  private

  def parsed_body
    JSON.parse(response.body)
  end
end
