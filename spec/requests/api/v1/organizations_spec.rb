require "rails_helper"

RSpec.describe "Api::V1::Organizations" do
  let(:admin) { create(:user) }
  let(:member) { create(:user) }
  let(:organization) { create(:organization) }

  before do
    create(:organization_membership, :admin, user: admin, organization: organization)
    create(:organization_membership, user: member, organization: organization)
  end

  describe "GET /api/v1/organizations" do
    it "returns organizations without authentication" do
      get "/api/v1/organizations"

      expect(response).to have_http_status(:ok)
      expect(parsed_body["data"].length).to eq(1)
    end
  end

  describe "GET /api/v1/organizations/:slug" do
    it "returns an organization by slug" do
      get "/api/v1/organizations/#{organization.slug}"

      expect(response).to have_http_status(:ok)
      expect(parsed_body.dig("data", "attributes", "name")).to eq(organization.name)
    end

    it "returns 404 for unknown slug" do
      get "/api/v1/organizations/nonexistent"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/organizations/:slug" do
    it "allows admin to update" do
      patch "/api/v1/organizations/#{organization.slug}",
        params: { data: { attributes: { name: "New Name" } } },
        headers: auth_headers_for(admin)

      expect(response).to have_http_status(:ok)
      expect(organization.reload.name).to eq("New Name")
    end

    it "forbids member from updating" do
      patch "/api/v1/organizations/#{organization.slug}",
        params: { data: { attributes: { name: "Hacked" } } },
        headers: auth_headers_for(member)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/organizations/:slug" do
    it "allows admin to soft delete" do
      delete "/api/v1/organizations/#{organization.slug}",
        headers: auth_headers_for(admin)

      expect(response).to have_http_status(:no_content)
      expect(Organization.find_by(id: organization.id)).to be_nil
      expect(Organization.with_deleted.find(organization.id).deleted?).to be true
    end
  end

  private

  def parsed_body
    JSON.parse(response.body)
  end
end
