module AuthHelpers
  def auth_headers_for(user, organization: nil)
    token = Doorkeeper::AccessToken.create!(
      resource_owner_id: user.id,
      scopes: "public",
      expires_in: 2.hours
    )
    headers = { "Authorization" => "Bearer #{token.token}" }
    headers["X-Org-Id"] = organization.id.to_s if organization
    headers
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
