# frozen_string_literal: true

module Wings
  class Persister
    attr_reader :adapter
    extend Forwardable
    def_delegator :adapter, :resource_factory
    # delegate :resource_factory, to: :adapter

    # @param [MetadataAdapter] adapter
    def initialize(adapter:)
      @adapter = adapter
    end

    # Persists a resource using ActiveFedora
    # @param [Valkyrie::Resource] resource
    # @return [Valkyrie::Resource] the persisted/updated resource
    def save(resource:)
      af_object = resource_factory.from_resource(resource: resource)
      af_object.save!
      resource_factory.to_resource(object: af_object)
    end

    # Deletes a resource persisted using ActiveFedora
    # @param [Valkyrie::Resource] resource
    # @return [Valkyrie::Resource] the deleted resource
    def delete(resource:)
      af_object = resource_factory.from_resource(resource: resource)
      af_object.delete #TODO: eradicate as well?
      resource
    end
  end
end
