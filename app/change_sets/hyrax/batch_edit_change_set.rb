# frozen_string_literal: true

module Hyrax
  class BatchEditChangeSet < WorkChangeSet
    property :creator, virtual: true, multiple: true, required: false
    property :contributor, virtual: true, multiple: true, required: false
    property :description, virtual: true, multiple: true, required: false
    property :keyword, virtual: true, multiple: true, required: false
    property :resource_type, virtual: true, multiple: true, required: false
    property :license, virtual: true, multiple: true, required: false
    property :publisher, virtual: true, multiple: true, required: false
    property :date_created, virtual: true, multiple: true, required: false
    property :subject, virtual: true, multiple: true, required: false
    property :language, virtual: true, multiple: true, required: false
    property :identifier, virtual: true, multiple: true, required: false
    property :based_near, virtual: true, multiple: true, required: false
    property :related_url, virtual: true, multiple: true, required: false

    # A list of IDs to perform a batch operation on
    property :batch_document_ids, virtual: true, multiple: true, required: false

    # Contains a list of titles of all the works in the batch
    attr_accessor :names

    # @param [ActiveFedora::Base] model the model backing the form
    def initialize(*)
      super
      @names = []
      @combined_attributes = initialize_combined_fields
    end

    private

      attr_reader :combined_attributes

      # override this method if you need to initialize more complex RDF assertions (b-nodes)
      # @return [Hash<String, Array>] the list of unique values per field
      def initialize_combined_fields
        # For each of the files in the batch, set the attributes to be the concatenation of all the attributes
        # Optimize: https://github.com/samvera-labs/valkyrie/issues/284
        batch_document_ids.each do |doc_id|
          work = find_resource(doc_id)
          (schema.keys - ['batch_document_ids', 'append_id']).each do |field|
            fields[field] ||= []
            fields[field] = (fields[field] + work[field].to_a).uniq
          end
          names << work.to_s
        end
      end

      def find_resource(id)
        query_service.find_by(id: Valkyrie::ID.new(id.to_s))
      end

      def query_service
        Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
      end
  end
end
