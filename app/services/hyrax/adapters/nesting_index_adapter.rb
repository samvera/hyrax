module Hyrax
  module Adapters
    module NestingIndexAdapter
      # @!group Providing interface for a Samvera::NestingIndexer::Adapter

      # @api public
      # @param id [String]
      # @return Samvera::NestingIndexer::Document::PreservationDocument
      def self.find_preservation_document_by(id:)
        # Not everything is guaranteed to have library_collection_ids
        # If it doesn't have it, what do we do?
        parent_ids = find_preservation_parent_ids_for(id: id)
        Samvera::NestingIndexer::Documents::PreservationDocument.new(id: id, parent_ids: parent_ids)
      end

      # @api public
      # @param id [String]
      # @return Samvera::NestingIndexer::Document::PreservationDocument
      def self.find_preservation_parent_ids_for(id:)
        # Not everything is guaranteed to have library_collection_ids
        # If it doesn't have it, what do we do?
        fedora_object = ActiveFedora::Base.find(id)
        if fedora_object.respond_to?(:member_of_collection_ids)
          fedora_object.member_of_collection_ids
        else
          []
        end
      end

      # @api public
      # @param id [String]
      # @return Samvera::NestingIndexer::Documents::IndexDocument
      def self.find_index_document_by(id:)
        solr_document = find_solr_document_by(id: id)
        coerce_solr_document_to_index_document(document: solr_document, id: id)
      end

      # @api public
      # @deprecated
      # @yield Samvera::NestingIndexer::Document::PreservationDocument
      # rubocop:disable Lint/UnusedMethodArgument
      def self.each_preservation_document(&block)
        # TODO: Enable Lint/UnusedMethodArgument once implemented
        raise NotImplementedError
      end
      # rubocop:enable Lint/UnusedMethodArgument

      # @api public
      # @yieldparam id [String]
      # @yieldparam parent_id [Array<String>]
      # rubocop:disable Lint/UnusedMethodArgument
      def self.each_perservation_document_id_and_parent_ids(&block)
        # TODO: Enable Lint/UnusedMethodArgument once implemented
        raise NotImplementedError
      end
      # rubocop:enable Lint/UnusedMethodArgument

      # @api public
      #
      # From the given parameters, we will need to add them to the underlying SOLR document for the object
      #
      # @param id [String]
      # @param parent_ids [Array<String>]
      # @param ancestors [Array<String>]
      # @param pathnames [Array<String>]
      # @return Hash - the attributes written to the indexing layer
      def self.write_document_attributes_to_index_layer(id:, parent_ids:, ancestors:, pathnames:)
        solr_doc = ActiveFedora::Base.find(id).to_solr # What is the current state of the solr document

        # Now add the details from the nesting indexor to the document
        solr_doc[solr_field_name_for_storing_ancestors] = ancestors
        solr_doc[solr_field_name_for_storing_parent_ids] = parent_ids
        solr_doc[solr_field_name_for_storing_pathnames] = pathnames
        ActiveFedora::SolrService.add(solr_doc, commit: true)
        solr_doc
      end

      # @api public
      # @param document [Samvera::NestingIndexer::Documents::IndexDocument]
      # @param solr_field_name_for_ancestors [String] The SOLR field name we use to find children
      # @yield Samvera::NestingIndexer::Documents::IndexDocument
      def self.each_child_document_of(document:, &block)
        raw_child_solr_documents_of(parent_document: document).each do |solr_document|
          child_document = coerce_solr_document_to_index_document(document: solr_document, id: solr_document.fetch('id'))
          block.call(child_document)
        end
      end
      # @!endgroup

      # @!group Supporting methods for interface implementation

      # @api private
      # @todo Need to implement retrieving parent_ids, pathnames, and ancestors from the given document
      def self.coerce_solr_document_to_index_document(document:, id:)
        Samvera::NestingIndexer::Documents::IndexDocument.new(
          id: id,
          parent_ids: document.fetch(solr_field_name_for_storing_parent_ids) { [] },
          pathnames: document.fetch(solr_field_name_for_storing_pathnames) { [] },
          ancestors: document.fetch(solr_field_name_for_storing_ancestors) { [] }
        )
      end
      private_class_method :coerce_solr_document_to_index_document

      # @api private
      def self.find_solr_document_by(id:)
        query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids([id])
        document = ActiveFedora::SolrService.query(query, rows: 1).first
        raise "Unable to find SolrDocument with ID=#{id}" if document.nil?
        document
      end
      private_class_method :find_solr_document_by

      # @api private
      def self.nesting_configuration
        @nesting_configuration ||= Samvera::NestingIndexer.configuration
      end

      class << self
        delegate :solr_field_name_for_storing_pathnames, :solr_field_name_for_storing_ancestors, :solr_field_name_for_storing_parent_ids, to: :nesting_configuration
      end

      # @api private
      # @param parent_document [Curate::Indexer::Documents::IndexDocument]
      # @return [Hash] A raw response document from SOLR
      # @todo What is the appropriate suffix to apply to the solr_field_name?
      def self.raw_child_solr_documents_of(parent_document:)
        pathname_query = parent_document.pathnames.map do |pathname|
          ActiveFedora::SolrQueryBuilder.construct_query(solr_field_name_for_storing_ancestors => pathname.gsub('"', '\"'))
        end.join(" OR ")
        ActiveFedora::SolrService.query(pathname_query)
      end
      private_class_method :raw_child_solr_documents_of

      # @!endgroup
    end
  end
end
