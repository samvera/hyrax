# frozen_string_literal: true

module Hyrax
  # Indexes labels for linked_data_attributes into solr.
  # @example Add linked_data_attributes to be indexed into `self.linked_data_attributes` as symbols.
  #   self.linked_data_attributes = [:based_near]
  #
  # @todo This replicates current Hyrax DeepIndexingService behaviour of fetching from URI whenever
  #     #to_solr is called; ideally avoid this by getting data from solr_document where
  #     labels are already indexed; this would required a combined form of label and uri in solr
  class LinkedDataAttributesIndexer
    attr_reader :resource
    attr_reader :solr_hash

    class_attribute :linked_data_attributes
    self.linked_data_attributes = %i[
      based_near
    ]

    def initialize(resource)
      @resource = resource.fetch(:resource)
      @solr_hash = {}
    end

    def to_solr
      return {} unless @resource.work?
      linked_data_attributes.each do |ld_attribute_name|
        next unless resource.try(ld_attribute_name)
        stored_searchable_and_facetable(
          ld_attribute_name
        )
      end
      solr_hash
    end

    private

      # Fetch the labels and add data to the solr_hash Store as stored_searchable (_tesim) and facetable (_sim)
      def stored_searchable_and_facetable(ld_attribute_name)
        labels = fetch_labels(ld_attribute_name)
        ['_label_tesim', '_label_sim'].each_with_object(solr_hash) do |suffix, output|
          output["#{ld_attribute_name}#{suffix}".to_sym] = labels
        end
      end

      # Fetch labels for each RDF::URI in the given attribute name
      # @example call based_near
      #   resource.based_near.map { |ld_uri| fetch_label(ld_attribute_name, ld_uri) }
      #
      # @param ld_attribute_name [Symbol] the attribute name
      # @return [Array<String>] an array of labels
      def fetch_labels(ld_attribute_name)
        resource.send(ld_attribute_name).map do |value|
          if uri?(value)
            fetch_label(ld_attribute_name, value)
          else
            value # Don't try to fetch. The value is a literal.
          end
        end
      end

      def uri?(value)
        %w[http https].include? Addressable::URI.parse(value).scheme
      end

      # Fetch the label from the external source via Hyrax::LinkedDataResourceFactory
      #
      # @param ld_attribute_name [Symbol] the attribute name
      # @param ld_uri [RDF::URI] the uri
      # @return [String] single label
      def fetch_label(ld_attribute_name, ld_uri)
        factory = Hyrax::LinkedDataResourceFactory.for(ld_attribute_name, ld_uri)
        factory.fetch_external
      end
  end
end
