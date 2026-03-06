require "rails_helper"

RSpec.describe "Api::V1::FamilyInvitations" do
  let(:parent) { create(:user) }
  let(:family) { create(:family) }
  let(:other_user) { create(:user) }

  before do
    create(:family_membership, family: family, user: parent, role: :parent)
  end

  describe "GET /api/v1/family_invitations?family_id=:id" do
    let!(:invitation) { create(:family_invitation, family: family, created_by: parent) }

    it "returns invitations for a parent of the family" do
      get "/api/v1/family_invitations", params: { family_id: family.id },
        headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      expect(parsed_ids).to include(invitation.id.to_s)
    end

    it "returns invitations for a guardian of the family" do
      guardian = create(:user)
      create(:family_membership, family: family, user: guardian, role: :guardian)

      get "/api/v1/family_invitations", params: { family_id: family.id },
        headers: auth_headers_for(guardian)

      expect(response).to have_http_status(:ok)
      expect(parsed_ids).to include(invitation.id.to_s)
    end

    it "forbids viewers from listing invitations" do
      viewer = create(:user)
      create(:family_membership, family: family, user: viewer, role: :viewer)

      get "/api/v1/family_invitations", params: { family_id: family.id },
        headers: auth_headers_for(viewer)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids non-members from listing invitations" do
      get "/api/v1/family_invitations", params: { family_id: family.id },
        headers: auth_headers_for(other_user)

      expect(response).to have_http_status(:forbidden)
    end

    it "excludes soft-deleted invitations" do
      invitation.mark_as_deleted!

      get "/api/v1/family_invitations", params: { family_id: family.id },
        headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      expect(parsed_ids).not_to include(invitation.id.to_s)
    end
  end

  describe "GET /api/v1/family_invitations/:token" do
    let!(:invitation) { create(:family_invitation, family: family, created_by: parent) }

    it "returns the invitation without authentication" do
      get "/api/v1/family_invitations/#{invitation.token}"

      expect(response).to have_http_status(:ok)
      expect(parsed_body["data"]["id"]).to eq(invitation.id.to_s)
    end

    it "includes the family in the response" do
      get "/api/v1/family_invitations/#{invitation.token}"

      expect(response).to have_http_status(:ok)
      included_types = parsed_body["included"]&.map { |i| i["type"] } || []
      expect(included_types).to include("families")
    end

    it "returns 404 for an invalid token" do
      get "/api/v1/family_invitations/bogus-token"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/family_invitations" do
    let(:params) do
      {
        data: {
          attributes: { role: "viewer" },
          relationships: {
            family: { data: { type: "families", id: family.id.to_s } }
          }
        }
      }
    end

    it "allows a parent to create an invitation" do
      expect {
        post "/api/v1/family_invitations", params: params,
          headers: auth_headers_for(parent)
      }.to change(FamilyInvitation, :count).by(1)

      expect(response).to have_http_status(:created)
      invitation = FamilyInvitation.last
      expect(invitation.role).to eq("viewer")
      expect(invitation.family).to eq(family)
      expect(invitation.created_by).to eq(parent)
      expect(invitation.token).to be_present
    end

    it "allows a guardian to create an invitation" do
      guardian = create(:user)
      create(:family_membership, family: family, user: guardian, role: :guardian)

      expect {
        post "/api/v1/family_invitations", params: params,
          headers: auth_headers_for(guardian)
      }.to change(FamilyInvitation, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "forbids viewers from creating invitations" do
      viewer = create(:user)
      create(:family_membership, family: family, user: viewer, role: :viewer)

      expect {
        post "/api/v1/family_invitations", params: params,
          headers: auth_headers_for(viewer)
      }.not_to change(FamilyInvitation, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids non-members from creating invitations" do
      expect {
        post "/api/v1/family_invitations", params: params,
          headers: auth_headers_for(other_user)
      }.not_to change(FamilyInvitation, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 without authentication" do
      post "/api/v1/family_invitations", params: params

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/family_invitations/:id" do
    let!(:invitation) { create(:family_invitation, family: family, created_by: parent) }

    it "allows a parent to revoke an invitation" do
      delete "/api/v1/family_invitations/#{invitation.id}",
        headers: auth_headers_for(parent)

      expect(response).to have_http_status(:no_content)
      expect(invitation.reload).to be_deleted
    end

    it "forbids viewers from revoking invitations" do
      viewer = create(:user)
      create(:family_membership, family: family, user: viewer, role: :viewer)

      delete "/api/v1/family_invitations/#{invitation.id}",
        headers: auth_headers_for(viewer)

      expect(response).to have_http_status(:forbidden)
      expect(invitation.reload).not_to be_deleted
    end

    it "forbids non-members from revoking invitations" do
      delete "/api/v1/family_invitations/#{invitation.id}",
        headers: auth_headers_for(other_user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/family_invitations/:token/accept" do
    let!(:invitation) { create(:family_invitation, family: family, created_by: parent, role: :viewer) }

    it "creates a family membership for the accepting user" do
      expect {
        post "/api/v1/family_invitations/#{invitation.token}/accept",
          headers: auth_headers_for(other_user)
      }.to change(FamilyMembership, :count).by(1)

      expect(response).to have_http_status(:created)
      membership = FamilyMembership.last
      expect(membership.user).to eq(other_user)
      expect(membership.family).to eq(family)
      expect(membership.role).to eq("viewer")
    end

    it "assigns the role from the invitation" do
      parent_invite = create(:family_invitation, family: family, created_by: parent, role: :parent)

      post "/api/v1/family_invitations/#{parent_invite.token}/accept",
        headers: auth_headers_for(other_user)

      expect(response).to have_http_status(:created)
      expect(FamilyMembership.last.role).to eq("parent")
    end

    it "returns the existing membership if user already belongs to the family" do
      existing = create(:family_membership, family: family, user: other_user, role: :viewer)

      expect {
        post "/api/v1/family_invitations/#{invitation.token}/accept",
          headers: auth_headers_for(other_user)
      }.not_to change(FamilyMembership, :count)

      expect(response).to have_http_status(:ok)
      expect(parsed_body["data"]["id"]).to eq(existing.id.to_s)
    end

    it "includes family and user in the response" do
      post "/api/v1/family_invitations/#{invitation.token}/accept",
        headers: auth_headers_for(other_user)

      included_types = parsed_body["included"]&.map { |i| i["type"] } || []
      expect(included_types).to include("families", "users")
    end

    it "returns 404 for an invalid token" do
      post "/api/v1/family_invitations/bogus-token/accept",
        headers: auth_headers_for(other_user)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 without authentication" do
      post "/api/v1/family_invitations/#{invitation.token}/accept"

      expect(response).to have_http_status(:unauthorized)
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
