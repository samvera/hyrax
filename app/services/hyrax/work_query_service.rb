module Hyrax
  # Responsible for retrieving information based on the given work.
  #
  # @see ProxyDepositRequest
  # @see Hyrax::WorkRelation
  # @see SolrDocument
  # @see ActiveFedora::SolrService
  # @see ActiveFedora::SolrQueryBuilder
  # @note This was extracted from the ProxyDepositRequest, which was coordinating lots of effort. It was also an ActiveRecord object that required lots of Fedora/Solr interactions.
  class WorkQueryService
    # @param [String] id - The id of the work
    def initialize(id:)
      @id = id
    end
    attr_reader :id

    # @return [Boolean] if the work has been deleted
    def deleted_work?
      !Hyrax::Queries.exists?(id)
    end

    def work
      @work ||= Hyrax::Queries.find_by(id: Valkyrie::ID.new(id))
    end

    def to_s
      if deleted_work?
        'work not found'
      else
        solr_doc.to_s
      end
    end

    private

      def solr_doc
        @solr_doc ||= ::SolrDocument.new(solr_response['response']['docs'].first, solr_response)
      end

      def solr_response
        @solr_response ||= ActiveFedora::SolrService.get(query)
      end

      def query
        ActiveFedora::SolrQueryBuilder.construct_query_for_ids([id])
      end
  end
end
