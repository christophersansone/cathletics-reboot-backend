Rails.application.routes.default_url_options = {
  host: ENV.fetch("APP_HOST", "localhost"),
  port: ENV.fetch("APP_PORT", 3000),
  protocol: ENV.fetch("APP_PROTOCOL", "http")
}
