# frozen_string_literal: true
module Hyrax
  ##
  # Answers whether any direct member of a work has a representative the
  # user can see in a IIIF viewer, with a single Solr query.
  class ViewableChildWorksService
    ##
    # @param solr_document [::SolrDocument] the work's solr document
    # @param ability [::Ability] the current user's ability
    #
    # @return [Boolean]
    def self.viewable?(solr_document:, ability:)
      new(solr_document: solr_document, ability: ability).viewable?
    end

    attr_reader :solr_document, :ability, :solr_service

    def initialize(solr_document:, ability:, solr_service: Hyrax::SolrService)
      @solr_document = solr_document
      @ability = ability
      @solr_service = solr_service
    end

    # @return [Boolean]
    def viewable?
      return false if viewable_mime_filter.empty? || member_ids.empty?

      Hyrax::SolrQueryService.new(query: ["(#{viewable_mime_filter})"], solr_service: solr_service)
                             .with_join(from: 'hasRelatedMediaFragment_ssim', to: 'id',
                                        query: Hyrax::SolrQueryService.new.with_ids(ids: member_ids))
                             .accessible_by(ability: ability)
                             .count
                             .positive?
    end

    private

    def member_ids
      @member_ids ||= Array(solr_document.member_ids)
    end

    def viewable_mime_filter
      @viewable_mime_filter ||= [image_clause, av_clause, pdf_clause].compact.join(' OR ')
    end

    def image_clause
      'mime_type_ssi:image\/*' if Hyrax.config.iiif_image_server?
    end

    def av_clause
      'mime_type_ssi:audio\/* OR mime_type_ssi:video\/*' if Flipflop.iiif_av?
    end

    def pdf_clause
      'mime_type_ssi:application\/pdf' if Flipflop.iiif_pdf?
    end
  end
end
