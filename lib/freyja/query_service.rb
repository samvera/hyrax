# frozen_string_literal: true
module Freyja
  class QueryService
    attr_reader :services
    delegate :orm_class, to: :resource_factory

    # @param [ResourceFactory] resource_factory
    def initialize(*services)
      @services = services
    end

    ##
    # Find the Valkyrie Resources referenced by another Valkyrie Resource
    #
    # @param resource [<Valkyrie::Resource>]
    # @param property [Symbol] the property holding the references to another resource
    # @return [Array<Valkyrie::Resource>]
    # def find_references_by(resource:, property:, model: nil)
    #   services[0].find_references_by(resource: resource, property: property, model: model)
    # end

    # TODO how do the _all methods combine the two sets
    [:find_all,
      :find_all_of_model,
      :find_by,
      :find_by_alternate_identifier,
      :find_many_by_ids,
      :find_members,
      :find_references_by,
      :find_inverse_references_by,
      :find_inverse_references_by,
      :find_parents,
      :count_all_of_model].each do |method_name|
      define_method method_name do |*args,**opts|
        result = nil
        services.each do |service|
          result = service.send(method_name, *args, **opts)
          return result if result.present? && (!result.respond_to?(:any?) || result.any?)
        rescue Valkyrie::Persistence::ObjectNotFoundError
          next
        end

        return result unless result.nil?
        raise Valkyrie::Persistence::ObjectNotFoundError
      end
    end

    ##
    # Constructs a Valkyrie::Persistence::CustomQueryContainer using this
    # query service
    #
    # @return [Valkyrie::Persistence::CustomQueryContainer]
    def custom_queries
      @custom_queries ||= Freyja::CustomQueryContainer.new(query_service: self)
    end
  end
end
