module AuthHelpers
  def auth_headers_for(user)
    token = Doorkeeper::AccessToken.create!(
      resource_owner_id: user.id,
      scopes: "public",
      expires_in: 2.hours
    )
    { "Authorization" => "Bearer #{token.token}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
