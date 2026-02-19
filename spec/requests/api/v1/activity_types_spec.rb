require "rails_helper"

RSpec.describe "Api::V1::ActivityTypes" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:organization) { create(:organization) }
  let!(:activity_type) { create(:activity_type, organization: organization, name: "Football") }

  before do
    create(:organization_membership, :admin, user: admin, organization: organization)
    create(:organization_membership, user: member, organization: organization)
  end

  describe "GET /api/v1/organizations/:slug/activity_types" do
    it "returns activity types for the organization" do
      get "/api/v1/organizations/#{organization.slug}/activity_types",
        headers: auth_headers_for(member)

      expect(response).to have_http_status(:ok)
      expect(parsed_body["data"].length).to eq(1)
      expect(parsed_body["data"].first.dig("attributes", "name")).to eq("Football")
    end
  end

  describe "POST /api/v1/organizations/:slug/activity_types" do
    let(:params) { { data: { attributes: { name: "Basketball", description: "Winter hoops" } } } }

    it "allows admin to create" do
      expect {
        post "/api/v1/organizations/#{organization.slug}/activity_types",
          params: params,
          headers: auth_headers_for(admin)
      }.to change(ActivityType, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "forbids member from creating" do
      post "/api/v1/organizations/#{organization.slug}/activity_types",
        params: params,
        headers: auth_headers_for(member)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/organizations/:slug/activity_types/:id" do
    it "allows admin to update" do
      patch "/api/v1/organizations/#{organization.slug}/activity_types/#{activity_type.id}",
        params: { data: { attributes: { name: "Flag Football" } } },
        headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(activity_type.reload.name).to eq("Flag Football")
    end
  end

  describe "DELETE /api/v1/organizations/:slug/activity_types/:id" do
    it "allows admin to soft delete" do
      delete "/api/v1/organizations/#{organization.slug}/activity_types/#{activity_type.id}",
        headers: auth_headers_for(admin)

      expect(response).to have_http_status(:no_content)
      expect(ActivityType.find_by(id: activity_type.id)).to be_nil
    end
  end

  private

  def parsed_body
    JSON.parse(response.body)
  end
end
