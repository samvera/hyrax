class ValkyrieTransitionHelper
  class << self
    # Save an object
    # @param object [ActiveFedora::Base | Valkyrie::Resource] the object to be saved
    # @return [ActiveFedora::Base | Valkyrie::Resource | FalseClass] the saved object or false if save fails
    # @raise [ArgumentError]
    def save(object:)
      raise ArgumentError, "Object argument must be a Valkyrie::Resource or an ActiveFedora object" unless valkyrie_object?(object) || active_fedora_object?(object)
      return object.save if active_fedora_object?(object)
      save_resource(resource: object)
    end

    # Save a resource
    # @param resource [Valkyrie::Resource] the resource to be saved
    # @return [Valkyrie::Resource | FalseClass] the saved resource or false if save fails
    # @raise [ArgumentError]
    def save_resource(resource:)
      raise ArgumentError, "Resource argument must be a Valkyrie::Resource" unless valkyrie_object? resource
      Hyrax.persister.save(resource: resource)
    rescue Wings::Valkyrie::Persister::FailedSaveError
      false
    end

    # Reload an object
    # @param object [ActiveFedora::Base | Valkyrie::Resource] the object to be reloaded
    # @return [ActiveFedora::Base | Valkyrie::Resource | FalseClass] the reloaded object
    # @raise [Hyrax::ObjectNotFoundError, ArgumentError]
    def reload(object:)
      raise ArgumentError, "Object argument must be a Valkyrie::Resource or an ActiveFedora object" unless valkyrie_object?(object) || active_fedora_object?(object)
      return object.reload if active_fedora_object?(object)
      reload_resource(resource: object)
    end

    # Reload a resource
    # @param resource [Valkyrie::Resource] the resource to be reloaded
    # @return [Valkyrie::Resource | FalseClass] the reloaded resource
    # @raise [Hyrax::ObjectNotFoundError, ArgumentError]
    def reload_resource(resource:)
      raise ArgumentError, "Resource argument must be a Valkyrie::Resource" unless valkyrie_object? resource
      raise ArgumentError, "Resource argument must have an id assigned" unless resource.id
      Hyrax.query_service.find_by(id: resource.id)
    end

    # Determine if valkyrie processing should be used either because it was specifically requested (i.e. use_valkyrie == true)
    # or because at least one the objects is a valkyrie object.
    # @param use_valkyrie [Boolean] true if valkyrie processing was specifically requested.
    # @param objects [Array<ActiveFedora::Base, Valkyrie::Resource>] the set of objects to check; if any are valkyrie resources, then true is returned
    # @return [Boolean] true if valkyrie was requested or any of the objects is a valkyrie object
    def force_use_valkyrie(use_valkyrie: false, objects: [])
      use_valkyrie || (objects.any? { |o| valkyrie_object?(o) })
    end

    # Convert the objects to Valkyrie resources, if needed.
    # @param object [ActiveFedora::Base, Valkyrie::Resource] the object to convert to valkyrie if it isn't already
    # @return [Valkyrie::Resource]
    # @raise [ArgumentError]
    def to_resource(object)
      raise ArgumentError, "Object argument must be a Valkyrie::Resource or an ActiveFedora object" unless valkyrie_object?(object) || active_fedora_object?(object)
      return object if valkyrie_object?(object)
      object.valkyrie_resource
    end

    # Convert the objects to Active Fedora objects, if needed.
    # @param object [ActiveFedora::Base, Valkyrie::Resource] the object to convert to active fedora if it isn't already
    # @return [ActiveFedora::Base]
    # @raise [ArgumentError]
    def to_active_fedora(object)
      raise ArgumentError, "Object argument must be a Valkyrie::Resource or an ActiveFedora object" unless valkyrie_object?(object) || active_fedora_object?(object)
      return object if active_fedora_object?(object)
      Wings::ActiveFedoraConverter.new(resource: object).convert
    end

    # determine if the object is a valkyrie resource
    # @param object [ActiveFedora::Base | Valkyrie::Resource] the object being checked
    # @return true if it is a Valkyrie::Resource
    def valkyrie_object?(object)
      object.is_a? Valkyrie::Resource
    end

    # determine if the object is an ActiveFedora object
    # @param object [ActiveFedora::Base | Valkyrie::Resource] the object being checked
    # @return true if it is a ActiveFedora::Base
    def active_fedora_object?(object)
      object.is_a? ActiveFedora::Base
    end
  end
end
