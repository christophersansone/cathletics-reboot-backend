require "rails_helper"

RSpec.describe "Api::V1::Signup" do
  describe "POST /api/v1/signup" do
    let(:valid_params) do
      {
        data: {
          attributes: {
            first_name: "Jane",
            last_name: "Doe",
            email: "jane@example.com",
            password: "password"
          }
        }
      }
    end

    it "creates a user without authentication" do
      expect {
        post "/api/v1/signup", params: valid_params
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(parsed_body.dig("data", "attributes", "firstName")).to eq("Jane")
    end

    it "returns errors for invalid data" do
      post "/api/v1/signup", params: { data: { attributes: { first_name: "" } } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(parsed_body["errors"]).to be_present
    end
  end

  private

  def parsed_body
    JSON.parse(response.body)
  end
end
