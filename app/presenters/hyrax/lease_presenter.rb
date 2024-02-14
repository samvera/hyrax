# frozen_string_literal: true
module Hyrax
  # Presents leased objects
  class LeasePresenter
    include ModelProxy
    attr_accessor :solr_document

    delegate :human_readable_type, :visibility, :to_s, to: :solr_document

    # @param [SolrDocument] solr_document
    def initialize(solr_document)
      @solr_document = solr_document
    end

    def lease_expiration_date
      if solr_document.lease_expiration_date
        solr_document.lease_expiration_date.to_formatted_s(:rfc822)
      else
        solr_document.keys
      end
    end

    def visibility_after_lease
      solr_document.fetch('visibility_after_lease_ssim', []).first
    end

    def lease_history
      solr_document['lease_history_ssim']
    end

    def enforced?
      solr_document.lease_enforced?
    end
  end
end
