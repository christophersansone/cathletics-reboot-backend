Doorkeeper.configure do
  orm :active_record

  resource_owner_authenticator do
    User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end

  resource_owner_from_credentials do |_routes|
    user = User.find_by(email: params[:username])
    user if user&.authenticate(params[:password])
  end

  grant_flows %w[password client_credentials]

  access_token_expires_in 2.hours
  use_refresh_token

  default_scopes :public
  optional_scopes :admin

  # Skip authorization for trusted first-party apps
  skip_authorization do |_resource_owner, _client|
    true
  end

  # Use bcrypt-hashed tokens in production for security
  # hash_token_fallback_secret_key Rails.application.credentials.secret_key_base
  # hash_application_secrets using: "Doorkeeper::SecretStoring::BCrypt"
end
