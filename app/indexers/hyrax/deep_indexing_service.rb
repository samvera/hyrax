# frozen_string_literal: true
require 'linkeddata' # we need all the linked data types, because we don't know what types a service might return.
module Hyrax
  class DeepIndexingService < BasicMetadataIndexer
    # We're overiding the default indexer in order to index the RDF labels. In order
    # for this to be called, you must specify at least one default indexer on the property.
    # @param [Hash] solr_doc
    # @param [String] solr_field_key
    # @param [Hash] field_info
    # @param [ActiveTriples::Resource, String] val
    def append_to_solr_doc(solr_doc, solr_field_key, field_info, val)
      return super unless object.controlled_properties.include?(solr_field_key.to_sym)
      case val
      when ActiveTriples::Resource
        append_label_and_uri(solr_doc, solr_field_key, field_info, val)
      when String
        append_label(solr_doc, solr_field_key, field_info, val)
      else
        raise ArgumentError, "Can't handle #{val.class}"
      end
    end

    def add_assertions(*)
      fetch_external
      super
    end

    private

    # Grab the labels for controlled properties from the remote sources
    def fetch_external
      object.controlled_properties.each do |property|
        object[property].each do |value|
          resource = value.respond_to?(:resource) ? value.resource : value
          next unless resource.is_a?(ActiveTriples::Resource)
          next if value.is_a?(ActiveFedora::Base)
          fetch_with_persistence(resource)
        end
      end
    end

    def fetch_with_persistence(resource)
      old_label = resource.rdf_label.first
      return unless old_label == resource.rdf_subject.to_s
      fetch_value(resource)
      return if old_label == resource.rdf_label.first || resource.rdf_label.first == resource.rdf_subject.to_s
      resource.persist! # Stores the fetched values into our marmotta triplestore
    end

    def fetch_value(value)
      Hyrax.logger.info "Fetching #{value.rdf_subject} from the authorative source. (this is slow)"
      value.fetch(headers: { 'Accept' => default_accept_header })
    rescue IOError, SocketError => e
      # IOError could result from a 500 error on the remote server
      # SocketError results if there is no server to connect to
      Hyrax.logger.error "Unable to fetch #{value.rdf_subject} from the authorative source.\n#{e.message}"
    end

    # Stripping off the */* to work around https://github.com/rails/rails/issues/9940
    def default_accept_header
      RDF::Util::File::HttpAdapter.default_accept_header.sub(/, \*\/\*;q=0\.1\Z/, '')
    end

    # Appends the uri to the default solr field and puts the label (if found) in the label solr field
    # @param [Hash] solr_doc
    # @param [String] solr_field_key
    # @param [Hash] field_info
    # @param [Array] val an array of two elements, first is a string (the uri) and the second is a hash with one key: `:label`
    def append_label_and_uri(solr_doc, solr_field_key, field_info, val)
      val = val.solrize
      ActiveFedora::Indexing::Inserter.create_and_insert_terms(solr_field_key,
                                                               val.first,
                                                               field_info.behaviors, solr_doc)
      return unless val.last.is_a? Hash
      ActiveFedora::Indexing::Inserter.create_and_insert_terms("#{solr_field_key}_label",
                                                               label(val),
                                                               field_info.behaviors, solr_doc)
    end

    # Use this method to append a string value from a controlled vocabulary field
    # to the solr document. It just puts a copy into the corresponding label field
    # @param [Hash] solr_doc
    # @param [String] solr_field_key
    # @param [Hash] field_info
    # @param [String] val
    def append_label(solr_doc, solr_field_key, field_info, val)
      ActiveFedora::Indexing::Inserter.create_and_insert_terms(solr_field_key,
                                                               val,
                                                               field_info.behaviors, solr_doc)
      ActiveFedora::Indexing::Inserter.create_and_insert_terms("#{solr_field_key}_label",
                                                               val,
                                                               field_info.behaviors, solr_doc)
    end

    # Return a label for the solrized term:
    # @example
    #   label(["http://id.loc.gov/authorities/subjects/sh85062487", {:label=>"Hotels$http://id.loc.gov/authorities/subjects/sh85062487"}])
    #   => 'Hotels'
    def label(val)
      val.last[:label].split('$').first
    end
  end
end
