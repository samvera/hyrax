# frozen_string_literal: true

module Hyrax
  class Queries
    class_attribute :metadata_adapter
    self.metadata_adapter = Valkyrie.config.metadata_adapter
    class << self
      delegate :exists?, :find_all, :find_all_of_model, :find_by, :find_members, :find_inverse_references_by, to: :default_adapter

      def default_adapter
        new(metadata_adapter: metadata_adapter)
      end
    end

    attr_reader :metadata_adapter
    delegate :find_all, :find_all_of_model, :find_by, :find_members, :find_inverse_references_by, to: :metadata_adapter_query_service
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
  end
end
