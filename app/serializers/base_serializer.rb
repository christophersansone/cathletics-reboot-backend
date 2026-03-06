class BaseSerializer < LegendaryJsonApi::Serializer

  def self.url_helpers
    Rails.application.routes.url_helpers
  end
end
