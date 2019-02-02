# frozen_string_literal: true

module Wings
  module Valkyrie
    class Persister
      attr_reader :adapter
      extend Forwardable
      def_delegator :adapter, :resource_factory

      # @param adapter [Wings::Valkyrie::MetadataAdapter] The adapter which holds the resource_factory for this persister.
      # @note Many persister methods are part of Valkyrie's public API, but instantiation itself is not
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

      # # Persists a resource using ActiveFedora
      # # @param [Valkyrie::Resource] resource
      # # @return [Valkyrie::Resource] the persisted/updated resource
      # def save_all(resources:)
      #   resources.map do |resource|
      #     save(resource: resource)
      #   end
      # end
      #
      # # Deletes a resource persisted using ActiveFedora
      # # @param [Valkyrie::Resource] resource
      # # @return [Valkyrie::Resource] the deleted resource
      # def delete(resource:)
      #   af_object = resource_factory.from_resource(resource: resource)
      #   af_object.delete
      # end
      #
      # # Deletes all resources from Fedora and Solr
      # def wipe!
      #   ActiveFedora::SolrService.instance.conn.delete_by_query("*:*")
      #   ActiveFedora::SolrService.instance.conn.commit
      #   ActiveFedora::Cleaner.clean!
      # end
    end
  end
end
