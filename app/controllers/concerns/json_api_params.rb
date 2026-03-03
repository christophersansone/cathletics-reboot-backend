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

end
