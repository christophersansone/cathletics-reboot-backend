require "rails_helper"

RSpec.describe "Api::V1::Me" do
  let(:user) { create(:user, first_name: "Tom", last_name: "Smith") }

  describe "GET /api/v1/me" do
    it "returns the authenticated user" do
      get "/api/v1/me", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(parsed_body.dig("data", "attributes", "firstName")).to eq("Tom")
    end

    it "returns 401 without a token" do
      get "/api/v1/me"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/me" do
    it "updates the authenticated user" do
      patch "/api/v1/me",
        params: { data: { attributes: { first_name: "Thomas" } } },
        headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      expect(user.reload.first_name).to eq("Thomas")
    end
  end

  private

  def parsed_body
    JSON.parse(response.body)
  end
end
