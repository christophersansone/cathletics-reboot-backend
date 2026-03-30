module JsonApiParams
  extend ActiveSupport::Concern

  def json_api_id
    params.require(:data).require(:id)
  end

  def json_api_attributes(*attrs)
    underscored_attributes = params.require(:data).require(:attributes).deep_transform_keys(&:underscore)
    underscored_attributes.permit(*attrs).to_h
  end

  def json_api_relationships(*rels)
    underscored_relationships = params.require(:data).require(:relationships).deep_transform_keys(&:underscore)
    permit = rels.map { |r| { r => { data: :id } } }
    permitted = underscored_relationships.permit(*permit).to_h
    result = {}
    permitted.each_pair { |k,v| result["#{k}_id"] = v && v[:data] && v[:data][:id] }
    result.with_indifferent_access
  end

  def json_api_polymorphic_relationships(*rels)
    underscored_relationships = params.require(:data).require(:relationships).deep_transform_keys(&:underscore)
    permit = rels.map { |r| { r => { data: [:type, :id] } } }
    permitted = underscored_relationships.permit(*permit).to_h
    result = {}
    permitted.each_pair do |k, v|
      raw_type = v && v[:data] && v[:data][:type]
      result["#{k}_type"] = raw_type.present? ? raw_type.to_s.singularize.classify : nil
      result["#{k}_id"] = v && v[:data] && v[:data][:id]
    end
    result.with_indifferent_access
  end

  # Array / JSON attributes (exdates, cancelled_occurrences, etc.) that must not go through
  # ActionController::Parameters#permit (unknown nesting). Clients may send camelCase keys
  # (e.g. Ember); normalize to snake_case before reading.
  def json_api_raw_attributes(*attrs)
    underscored_attributes = params.require(:data).require(:attributes).deep_transform_keys(&:underscore).to_unsafe_h
    result = {}
    attrs.each do |attr|
      result[attr] = underscored_attributes[attr] if underscored_attributes.has_key?(attr)
    end
    result.with_indifferent_access
  end

end
