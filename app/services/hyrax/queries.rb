# frozen_string_literal: true

module Hyrax
  class ObjectNotFoundError < StandardError
  end

  class Queries
    class_attribute :metadata_adapter
    self.metadata_adapter = Valkyrie.config.metadata_adapter
    class << self
      delegate :exists?, :find_work, :find_file_set, :find_collection,
               :find_all, :find_by, :find_all_of_model, :find_members,
               :find_references_by, :find_inverse_references_by, :find_parents,
               :custom_queries, to: :default_adapter

      def default_adapter
        new(metadata_adapter: metadata_adapter)
      end
    end

    attr_reader :metadata_adapter
    delegate :find_all, :custom_queries, to: :metadata_adapter_query_service
    def initialize(metadata_adapter:)
      @metadata_adapter = metadata_adapter
    end

    def exists?(id)
      find_by(id: id)
      return true
    rescue Valkyrie::Persistence::ObjectNotFoundError
      return false
    end

    delegate :query_service, to: :metadata_adapter, prefix: true

    # The methods below are wrapped instead of delegated so Valkyrie's shared specs will pass
    def find_by(id:)
      metadata_adapter_query_service.find_by(id: id)
    end

    def find_all_of_model(model:)
      metadata_adapter_query_service.find_all_of_model(model: model)
    end

    def find_members(resource:, model: nil)
      metadata_adapter_query_service.find_members(resource: resource, model: model)
    end

    def find_parents(resource:)
      metadata_adapter_query_service.find_parents(resource: resource)
    end

    def find_references_by(resource:, property:)
      metadata_adapter_query_service.find_references_by(resource: resource, property: property)
    end

    def find_inverse_references_by(resource:, property:)
      metadata_adapter_query_service.find_inverse_references_by(resource: resource, property: property)
    end

    def find_work(id:)
      resource = find_by(id: id)
      raise Hyrax::ObjectNotFoundError, "Couldn't find work with 'id'=#{id}" unless resource.work?
      resource
    end

    def find_file_set(id:)
      resource = find_by(id: id)
      raise Hyrax::ObjectNotFoundError, "Couldn't find file set with 'id'=#{id}" unless resource.file_set?
      resource
    end

    def find_collection(id:)
      resource = find_by(id: id)
      raise Hyrax::ObjectNotFoundError, "Couldn't find collection with 'id'=#{id}" unless resource.collection?
      resource
    end
  end
end
