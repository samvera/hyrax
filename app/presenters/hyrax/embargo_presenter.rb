# frozen_string_literal: true
module Hyrax
  # Presents embargoed objects
  class EmbargoPresenter
    include ModelProxy
    attr_accessor :solr_document

    delegate :human_readable_type, :visibility, :to_s, to: :solr_document

    # @param [SolrDocument] solr_document
    def initialize(solr_document)
      @solr_document = solr_document
    end

    def embargo_release_date
      solr_document.embargo_release_date.to_formatted_s(:rfc822)
    end

    def visibility_after_embargo
      solr_document.fetch('visibility_after_embargo_ssim', []).first
    end

    def embargo_history
      solr_document['embargo_history_ssim']
    end

    def enforced?
      solr_document.embargo_enforced?
    end
  end
end
