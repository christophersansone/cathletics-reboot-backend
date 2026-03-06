require "rails_helper"

RSpec.describe "Api::V1::Children" do
  let(:parent) { create(:user) }
  let(:family) { create(:family) }
  let(:other_user) { create(:user) }

  before do
    create(:family_membership, family: family, user: parent, role: :parent)
  end

  describe "POST /api/v1/children" do
    let(:params) do
      {
        data: {
          attributes: {
            first_name: "Lucy",
            last_name: "Smith",
            date_of_birth: "2018-05-15",
            grade_level: 2,
            gender: "female"
          },
          relationships: {
            family: { data: { type: "families", id: family.id.to_s } }
          }
        }
      }
    end

    it "creates a child user and family membership atomically" do
      expect {
        post "/api/v1/children", params: params,
          headers: auth_headers_for(parent)
      }.to change(User, :count).by(1)
        .and change(FamilyMembership, :count).by(1)

      expect(response).to have_http_status(:created)

      child = User.last
      expect(child.first_name).to eq("Lucy")
      expect(child.last_name).to eq("Smith")
      expect(child.grade_level).to eq(2)
      expect(child).to be_female

      membership = child.family_memberships.last
      expect(membership.family).to eq(family)
      expect(membership).to be_child
    end

    it "allows a guardian to create a child" do
      guardian = create(:user)
      create(:family_membership, family: family, user: guardian, role: :guardian)

      expect {
        post "/api/v1/children", params: params,
          headers: auth_headers_for(guardian)
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "forbids viewers from creating children" do
      viewer = create(:user)
      create(:family_membership, family: family, user: viewer, role: :viewer)

      expect {
        post "/api/v1/children", params: params,
          headers: auth_headers_for(viewer)
      }.not_to change(User, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids non-members from creating children" do
      expect {
        post "/api/v1/children", params: params,
          headers: auth_headers_for(other_user)
      }.not_to change(User, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "works with nested route" do
      expect {
        post "/api/v1/families/#{family.id}/children",
          params: { data: { attributes: { first_name: "Tom", last_name: "Smith", gender: "male" } } },
          headers: auth_headers_for(parent)
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "returns 401 without authentication" do
      post "/api/v1/children", params: params

      expect(response).to have_http_status(:unauthorized)
    end
  end

  private

  def parsed_body
    JSON.parse(response.body)
  end
end
