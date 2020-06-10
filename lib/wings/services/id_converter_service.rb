# frozen_string_literal: true
# Converson service for going between valkyrie_ids and fedora_ids
# NOTE: This is pretty heavy handed since it loads objects to get the converted ids.
module Wings
  class IdConverterService
    def self.convert_to_active_fedora_ids(valkyrie_ids)
      resources = valkyrie_ids.map { |id| Hyrax.query_service.find_by(id: id) }
      resources.map { |resource| resource.id.id } # TODO: What if id.id is empty?
    end

    def self.convert_to_valkyrie_resource_ids(fedora_ids)
      fedora_ids.map { |id| ActiveFedora::Base.find(id).valkyrie_resource.id }
    end
  end
end
