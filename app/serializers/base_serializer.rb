class BaseSerializer < LegendaryJsonApi::Serializer

  def self.url_helpers
    Rails.application.routes.url_helpers
  end

  def self.polymorphic_serializer
    @polymorphic_serializer ||= Proc.new { |object| puts 'a'; puts LegendaryJsonApi::Serialization::Resolver.resolve(object); LegendaryJsonApi::Serialization::Resolver.resolve(object) }
  end
end
