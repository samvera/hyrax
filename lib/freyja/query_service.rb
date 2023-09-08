# frozen_string_literal: true
module Freyja
  class QueryService
    attr_reader :services
    delegate :orm_class, to: :resource_factory

    # @param [QueryService] query_service
    def initialize(*services)
      @services = services
    end

    # NOTE: - this number may be overinflated. we dont have a good way to remove items in both from the count
    def self.count_multiple(method_name)
      # look in all services, combine and uniq results
      define_method method_name do |*args, **opts|
        opts[:model] = model_class_for(opts[:model]) if opts[:model]
        total_result = 0
        services.each do |service|
          result = service.send(method_name, *args, **opts)
          total_result += result if result.present?
        rescue Valkyrie::Persistence::ObjectNotFoundError
          next
        end

        return total_result
      end
    end

    def self.find_multiple(method_name)
      # look in all services, combine and uniq results
      define_method method_name do |*args, **opts|
        opts[:model] = model_class_for(opts[:model]) if opts[:model]
        total_result = []
        services.each do |service|
          result = service.send(method_name, *args, **opts)
          total_result += result.to_a if result.present? && result.respond_to?(:any?) && result.any?
        rescue Valkyrie::Persistence::ObjectNotFoundError
          next
        end

        total_result.uniq!(&:alternate_ids)
        return total_result
      end
    end

    def self.find_single(method_name)
      define_method method_name do |*args, **opts|
        opts[:model] = model_class_for(opts[:model]) if opts[:model]
        result = nil
        services.each do |service|
          result = service.send(method_name, *args, **opts)
          return result if result.present?
        rescue Valkyrie::Persistence::ObjectNotFoundError
          next
        end

        return result unless result.nil?
        raise Valkyrie::Persistence::ObjectNotFoundError
      end
    end

    [:find_all,
     :find_all_of_model,
     :find_many_by_ids,
     :find_members,
     :find_references_by,
     :find_inverse_references_by,
     :find_inverse_references_by,
     :find_parents].each do |method_name|
      find_multiple(method_name)
    end

    [:find_by,
     :find_by_alternate_identifier].each do |method_name|
      find_single(method_name)
    end

    [:count_all_of_model].each do |method_name|
      count_multiple(method_name)
    end

    ##
    # Constructs a Valkyrie::Persistence::CustomQueryContainer using this
    # query service
    #
    # @return [Valkyrie::Persistence::CustomQueryContainer]
    def custom_queries
      @custom_queries ||= Freyja::CustomQueryContainer.new(query_service: self)
    end

    def model_class_for(model)
      internal_resource = model.respond_to?(:internal_resource) ? model.internal_resource : nil
      internal_resource&.safe_constantize || Wings::ModelRegistry.lookup(model)
    end
  end
end
