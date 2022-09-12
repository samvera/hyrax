# frozen_string_literal: true
module Hyrax
  # Responsible for retrieving information based on the given work.
  #
  # @see ProxyDepositRequest
  # @see SolrDocument
  # @see Hyrax::SolrService
  # @note This was extracted from the ProxyDepositRequest, which was coordinating lots of effort. It was also an ActiveRecord object that required lots of Fedora/Solr interactions.
  class WorkResourceQueryService
    # @param [String] id - The id of the work
    def initialize(id:)
      @id = id
    end
    attr_reader :id

    # @return [Boolean] if the work has been deleted
    def deleted_work?
      Hyrax.query_service.find_by(id: id)
      false
    rescue Valkyrie::Persistence::ObjectNotFoundError
      true
    end

    def work
      # Need to ensure it is a work?
      resource = Hyrax.query_service.find_by(id: id)
      unless Hyrax.config.curation_concerns.include?(resource.class) ||
             Hyrax.config.curation_concerns.map(&:to_s).include?(resource.class.to_s) || # Wings-wrapped models
             Hyrax.config.curation_concerns.map(&:to_s).include?(resource.class.name) # Wings-wrapped models
        raise ModelMismatchError, "Expected allowed work type but got #{resource.class}"
      end
      resource
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
      @solr_doc ||= ::SolrDocument.new(Hyrax::SolrService.search_by_id(id))
    end
  end
end
