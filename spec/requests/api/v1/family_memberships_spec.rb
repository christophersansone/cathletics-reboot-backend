require "rails_helper"

RSpec.describe "Api::V1::FamilyMemberships" do
  let(:parent) { create(:user) }
  let(:family) { create(:family) }
  let(:other_user) { create(:user) }
  let!(:parent_membership) { create(:family_membership, family: family, user: parent, role: :parent) }

  describe "GET /api/v1/family_memberships?family_id=:id" do
    let!(:child_membership) { create(:family_membership, :child, family: family) }

    it "returns memberships for a family member" do
      get "/api/v1/family_memberships", params: { family_id: family.id },
        headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      expect(parsed_ids).to include(parent_membership.id.to_s, child_membership.id.to_s)
    end

    it "allows viewers to list memberships" do
      viewer = create(:user)
      create(:family_membership, family: family, user: viewer, role: :viewer)

      get "/api/v1/family_memberships", params: { family_id: family.id },
        headers: auth_headers_for(viewer)

      expect(response).to have_http_status(:ok)
    end

    it "forbids non-members from listing memberships" do
      get "/api/v1/family_memberships", params: { family_id: family.id },
        headers: auth_headers_for(other_user)

      expect(response).to have_http_status(:forbidden)
    end

    it "excludes soft-deleted memberships" do
      child_membership.mark_as_deleted!

      get "/api/v1/family_memberships", params: { family_id: family.id },
        headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      expect(parsed_ids).not_to include(child_membership.id.to_s)
    end
  end

  describe "GET /api/v1/family_memberships/:id" do
    it "allows a family member to view a membership" do
      get "/api/v1/family_memberships/#{parent_membership.id}",
        headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      expect(parsed_body["data"]["id"]).to eq(parent_membership.id.to_s)
    end

    it "forbids non-members from viewing" do
      get "/api/v1/family_memberships/#{parent_membership.id}",
        headers: auth_headers_for(other_user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/family_memberships" do
    let(:new_user) { create(:user) }
    let(:params) do
      {
        data: {
          attributes: { role: "guardian" },
          relationships: {
            family: { data: { type: "families", id: family.id.to_s } },
            user: { data: { type: "users", id: new_user.id.to_s } }
          }
        }
      }
    end

    it "allows a parent to add a member" do
      expect {
        post "/api/v1/family_memberships", params: params,
          headers: auth_headers_for(parent)
      }.to change(FamilyMembership, :count).by(1)

      expect(response).to have_http_status(:created)
      membership = FamilyMembership.last
      expect(membership.user).to eq(new_user)
      expect(membership.family).to eq(family)
      expect(membership).to be_guardian
    end

    it "forbids viewers from adding members" do
      viewer = create(:user)
      create(:family_membership, family: family, user: viewer, role: :viewer)

      expect {
        post "/api/v1/family_memberships", params: params,
          headers: auth_headers_for(viewer)
      }.not_to change(FamilyMembership, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids non-members from adding members" do
      expect {
        post "/api/v1/family_memberships", params: params,
          headers: auth_headers_for(other_user)
      }.not_to change(FamilyMembership, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/family_memberships/:id" do
    let!(:child_membership) { create(:family_membership, :child, family: family) }

    it "allows a parent to update a membership role" do
      patch "/api/v1/family_memberships/#{child_membership.id}",
        params: { data: { attributes: { role: "guardian" } } },
        headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      expect(child_membership.reload).to be_guardian
    end

    it "forbids viewers from updating memberships" do
      viewer = create(:user)
      create(:family_membership, family: family, user: viewer, role: :viewer)

      patch "/api/v1/family_memberships/#{child_membership.id}",
        params: { data: { attributes: { role: "guardian" } } },
        headers: auth_headers_for(viewer)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/family_memberships/:id" do
    let!(:child_membership) { create(:family_membership, :child, family: family) }

    it "allows a parent to remove a member" do
      delete "/api/v1/family_memberships/#{child_membership.id}",
        headers: auth_headers_for(parent)

      expect(response).to have_http_status(:no_content)
      expect(child_membership.reload).to be_deleted
    end

    it "forbids viewers from removing members" do
      viewer = create(:user)
      create(:family_membership, family: family, user: viewer, role: :viewer)

      delete "/api/v1/family_memberships/#{child_membership.id}",
        headers: auth_headers_for(viewer)

      expect(response).to have_http_status(:forbidden)
      expect(child_membership.reload).not_to be_deleted
    end

    it "forbids non-members from removing members" do
      delete "/api/v1/family_memberships/#{child_membership.id}",
        headers: auth_headers_for(other_user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  private

  def parsed_body
    JSON.parse(response.body)
  end

  def parsed_ids
    parsed_body["data"].map { |d| d["id"] }
  end
end
