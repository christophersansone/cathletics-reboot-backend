class BaseSerializer < LegendaryJsonApi::Serializer
  class UrlHelpers
    include Rails.application.routes.url_helpers
  end

  def self.url_helpers
    @url_helpers ||= UrlHelpers.new
  end
end
