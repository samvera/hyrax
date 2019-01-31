# frozen_string_literal: true

module Wings
  class Persister
    # Persists a resource using ActiveFedora
    # @param [Valkyrie::Resource] resource
    # @return [Valkyrie::Resource] the persisted/updated resource
    def save(resource:)
      af_object = resource_factory.from_resource(resource: resource)
      af_object.save!
      resource_factory.to_resource(object: af_object)
    end

    # Persists a resource using ActiveFedora
    # @param [Valkyrie::Resource] resource
    # @return [Valkyrie::Resource] the persisted/updated resource
    def save_all(resources:)
      resources.map do |resource|
        save(resource: resource)
      end
    end

    # Deletes a resource persisted using ActiveFedora
    # @param [Valkyrie::Resource] resource
    # @return [Valkyrie::Resource] the deleted resource
    def delete(resource:)
      af_object = resource_factory.from_resource(resource: resource)
      af_object.destroy #TODO: eradicate as well?
    end
  end
end
