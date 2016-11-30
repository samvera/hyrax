PowerConverter.define_conversion_for(:sipity_entity) do |input|
  case input
  when URI::GID
    Sipity::Entity.find_by(proxy_for_global_id: input.to_s)
  when SolrDocument
    PowerConverter.convert_to_sipity_entity(input.to_model.to_global_id)
  when Sipity::Entity
    input
  when Sipity::Comment
    PowerConverter.convert_to_sipity_entity(input.entity)
  end
end
