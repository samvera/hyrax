# frozen_string_literal: true

module Hyrax
  ##
  # Implements the Fedora objState ontology against the given resource.
  #
  # Use the provided constants as values for `#status` to set state. The
  # boolean methods provide easy checking of state.
  #
  # We assume that no-state, means none of the three object statuses are
  # satisfied. Errors are raised if the `#state` attribute isn't defined.
  #
  # @see http://fedora.info/definitions/1/0/access/ObjState
  #
  # @example
  #   status = ResourceStatus.new(resource: my_resource)
  #   status.inactive? # => false
  #
  #   my_resource.state = ResourceStatus::INACTIVE
  #   status = ResourceStatus.new(resource: my_resource)
  #   status.inactive? # => true
  #
  class ResourceStatus
    ACTIVE   = Vocab::FedoraResourceStatus.active.freeze
    DELETED  = Vocab::FedoraResourceStatus.deleted.freeze
    INACTIVE = Vocab::FedoraResourceStatus.inactive.freeze

    ##
    # @!attribute [rw] resource
    #   @return [#state]
    attr_accessor :resource

    ##
    # @param [#state] resource
    def initialize(resource:)
      self.resource = resource
    end

    ##
    # @param [#state] resource
    # @return [Boolean]
    def self.inactive?(resource:)
      new(resource: resource).inactive?
    end

    ##
    # @return [Boolean]
    # @raise [NoMethodError] if the resource doesn't have a state attribute
    def active?
      resource.state == ACTIVE
    end

    ##
    # @return [Boolean]
    # @raise [NoMethodError] if the resource doesn't have a state attribute
    def deleted?
      resource.state == DELETED
    end

    ##
    # @return [Boolean]
    # @raise [NoMethodError] if the resource doesn't have a state attribute
    def inactive?
      resource.state == INACTIVE
    end
  end
end
