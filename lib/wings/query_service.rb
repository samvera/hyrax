# frozen_string_literal: true

module Wings
  class QueryService
    attr_reader :resource_factory, :adapter
    extend Forwardable
    def_delegator :resource_factory, :form_class
    # delegate :form_class, to: :resource_factory

    # @param [ResourceFactory] resource_factory
    def initialize(adapter:, resource_factory:)
      @resource_factory = resource_factory
      @adapter = adapter
    end

    # Find a record using a Valkyrie ID, and map it to a Valkyrie Resource
    # @param [Valkyrie::ID, String] id
    # @return [Valkyrie::Resource]
    # @raise [Valkyrie::Persistence::ObjectNotFoundError]
    def find_by(id:)
      resource_factory.to_resource(object: ::ActiveFedora::Base.find(id.to_s))
    rescue ::ActiveFedora::ObjectNotFoundError
      raise ::Valkyrie::Persistence::ObjectNotFoundError
    end
  end
end
