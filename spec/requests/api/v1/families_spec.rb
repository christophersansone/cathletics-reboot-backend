require "rails_helper"

RSpec.describe "Api::V1::Families" do
  let(:parent) { create(:user) }
  let(:other_user) { create(:user) }
  let(:family) { create(:family) }

  before do
    create(:family_membership, family: family, user: parent, role: :parent)
  end

  describe "GET /api/v1/families" do
    it "returns families for the authenticated user" do
      create(:family) # other family

      get "/api/v1/families", headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      expect(parsed_body["data"].length).to eq(1)
    end
  end

  describe "GET /api/v1/families/:id" do
    it "allows a family member to view their family" do
      get "/api/v1/families/#{family.id}", headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
    end

    it "forbids non-members from viewing" do
      get "/api/v1/families/#{family.id}", headers: auth_headers_for(other_user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/families" do
    it "creates a family and adds the user as parent" do
      expect {
        post "/api/v1/families",
          params: { data: { attributes: { name: "The New Family" } } },
          headers: auth_headers_for(parent)
      }.to change(Family, :count).by(1)

      expect(response).to have_http_status(:created)
      new_family = Family.last
      expect(new_family.family_memberships.find_by(user: parent)).to be_parent
    end
  end

  describe "PATCH /api/v1/families/:id" do
    it "allows a parent to update family name" do
      patch "/api/v1/families/#{family.id}",
        params: { data: { attributes: { name: "Updated Name" } } },
        headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      expect(family.reload.name).to eq("Updated Name")
    end
  end

  private

  def parsed_body
    JSON.parse(response.body)
  end
end
