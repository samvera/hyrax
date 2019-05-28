# frozen_string_literal: true

module Wings
  class ActiveFedoraReloaderService
    # For replacing calls to reload on ActiveFedora objects

    def self.reload(af_object)
      return af_object unless af_object.persisted?

      adapter = Hyrax.config.valkyrie_metadata_adapter
      resource = adapter.query_service.find_by(id: af_object.id)
      af_object.clear_association_cache
      retrieved_object = adapter.resource_factory.from_resource(resource: resource)
      af_object.association_cache.merge! retrieved_object.association_cache
      af_object.ldp_source.graph.clear!
      af_object.ldp_source.graph << retrieved_object.ldp_source.graph
      af_object
    end
  end
end
