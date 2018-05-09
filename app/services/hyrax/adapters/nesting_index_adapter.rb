module Hyrax
  module Adapters
    module NestingIndexAdapter
      FULL_REINDEX = "full".freeze
      LIMITED_REINDEX = "limited".freeze

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
        fedora_object = ActiveFedora::Base.uncached do
          fedora_object = ActiveFedora::Base.find(id)
        end

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
        coerce_solr_document_to_index_document(original_solr_document: solr_document, id: id)
      end

      # @api public
      # @yieldparam id [String]
      # @yieldparam parent_id [Array<String>]
      # Samvera::NestingIndexer.reindex_all!(extent: FULL_REINDEX)
      # rubocop:disable Lint/UnusedMethodArgument
      def self.each_perservation_document_id_and_parent_ids(&block)
        ActiveFedora::Base.descendant_uris(ActiveFedora.fedora.base_uri, exclude_uri: true).each do |uri|
          id = ActiveFedora::Base.uri_to_id(uri)
          object = ActiveFedora::Base.find(id)
          parent_ids = object.try(:member_of_collection_ids) || []

          # note: we do not yield when the object has parents. Calling the nested indexer for the
          # top id will reindex all descendants as well.
          if object.try(:use_nested_reindexing?)
            yield(id, parent_ids) if parent_ids.empty?
          else
            Rails.logger.info "Re-indexing via to_solr ... #{id}"
            ActiveFedora::SolrService.add(object.to_solr, commit: true)
          end
        end
      end
      # rubocop:enable Lint/UnusedMethodArgument

      # @api public
      #
      # From the nesting_document, we will need to add the nesting attributes to the underlying SOLR document for the object
      #
      # @param nesting_document [Samvera::NestingIndexer::Documents::IndexDocument]
      # @return Hash - the attributes written to the indexing layer
      def self.write_nesting_document_to_index_layer(nesting_document:)
        solr_doc = ActiveFedora::Base.uncached do
          ActiveFedora::Base.find(nesting_document.id).to_solr # What is the current state of the solr document
        end

        # Now add the details from the nesting indexer to the document
        add_nesting_attributes(
          solr_doc: solr_doc,
          ancestors: nesting_document.ancestors,
          parent_ids: nesting_document.parent_ids,
          pathnames: nesting_document.pathnames,
          depth: nesting_document.deepest_nested_depth
        )
      end

      # @api public
      #
      # @param solr_doc [SolrDocument]
      # @param ancestors [Array]
      # @param parent_ids [Array]
      # @param pathnames [Array]
      # @param depth [Array] the object's deepest nesting depth
      # @return solr_doc [SolrDocument]
      def self.add_nesting_attributes(solr_doc:, ancestors:, parent_ids:, pathnames:, depth:)
        solr_doc[solr_field_name_for_storing_ancestors] = ancestors
        solr_doc[solr_field_name_for_storing_parent_ids] = parent_ids
        solr_doc[solr_field_name_for_storing_pathnames] = pathnames
        solr_doc[solr_field_name_for_deepest_nested_depth] = depth
        ActiveFedora::SolrService.add(solr_doc, commit: true)
        solr_doc
      end

      # @api public
      # @param document [Samvera::NestingIndexer::Documents::IndexDocument]
      # @param extent [String] if not "full" or nil, doesn't yield children for reindexing
      # @param solr_field_name_for_ancestors [String] The SOLR field name we use to find children
      # @yield Samvera::NestingIndexer::Documents::IndexDocument
      def self.each_child_document_of(document:, extent:, &block)
        raw_child_solr_documents_of(parent_document: document).each do |solr_document|
          child_document = coerce_solr_document_to_index_document(original_solr_document: solr_document, id: solr_document.fetch('id'))
          # during light reindexing, we want to reindex the child only if fields aren't already there
          block.call(child_document) if full_reindex?(extent: extent) || child_document.pathnames.empty?
        end
      end
      # @!endgroup

      # @!group Supporting methods for interface implementation

      # @api private
      # @todo Need to implement retrieving parent_ids, pathnames, and ancestors from the given document
      def self.coerce_solr_document_to_index_document(original_solr_document:, id:)
        Samvera::NestingIndexer::Documents::IndexDocument.new(
          id: id,
          parent_ids: original_solr_document.fetch(solr_field_name_for_storing_parent_ids) { [] },
          pathnames: original_solr_document.fetch(solr_field_name_for_storing_pathnames) { [] },
          ancestors: original_solr_document.fetch(solr_field_name_for_storing_ancestors) { [] }
        )
      end
      private_class_method :coerce_solr_document_to_index_document

      # @api private
      def self.find_solr_document_by(id:)
        query = ActiveFedora::SolrQueryBuilder.construct_query_for_ids([id])
        document = ActiveFedora::SolrService.query(query, rows: 1).first
        document = ActiveFedora::Base.find(id).to_solr if document.nil?
        raise "Unable to find SolrDocument with ID=#{id}" if document.nil?
        document
      end
      private_class_method :find_solr_document_by

      # @api private
      def self.nesting_configuration
        @nesting_configuration ||= Samvera::NestingIndexer.configuration
      end

      class << self
        delegate :solr_field_name_for_storing_pathnames,
                 :solr_field_name_for_storing_ancestors,
                 :solr_field_name_for_storing_parent_ids,
                 :solr_field_name_for_deepest_nested_depth, to: :nesting_configuration
      end

      # @api private
      # @param parent_document [Curate::Indexer::Documents::IndexDocument]
      # @return [Hash] A raw response document from SOLR
      # @todo What is the appropriate suffix to apply to the solr_field_name?
      def self.raw_child_solr_documents_of(parent_document:)
        # query Solr for all of the documents included as a member_of_collection parent. Or up to 10000 of them.
        child_query = ActiveFedora::SolrQueryBuilder.construct_query(member_of_collection_ids_ssim: parent_document.id)
        ActiveFedora::SolrService.query(child_query, rows: 10_000.to_i)
      end
      private_class_method :raw_child_solr_documents_of

      def self.full_reindex?(extent:)
        return true if extent == FULL_REINDEX
        false
      end
      private_class_method :full_reindex?
      # @!endgroup
    end
  end
end
