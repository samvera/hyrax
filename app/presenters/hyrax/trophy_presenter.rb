# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Presents works in context as "trophied" for a given user.
  #
  # @example
  #   my_user = User.find(user_id)
  #
  #   trophies = Hyrax::TrophyPresenter.find_by_user(my_user)
  #   trophies.each do |trophy|
  #     puts "Object name/title: #{trophy}"
  #     puts "Thumbnail path: #{trophy.thumbnail_path}"
  #   end
  class TrophyPresenter
    include ModelProxy

    ##
    # @param solr_document [::SolrDocument]
    def initialize(solr_document)
      @solr_document = solr_document
    end

    ##
    # @!attribute [r] SolrDocument
    #   @return [::SolrDocument]
    attr_reader :solr_document

    delegate :to_s, :thumbnail_path, to: :solr_document

    ##
    # @param user [User] the user to find the TrophyPresentes for.
    #
    # @return [Array<TrophyPresenter>] a list of all the trophy presenters for the user
    def self.find_by_user(user)
      ids = user.trophies.pluck(:work_id)
      return ids if ids.empty?

      documents = Hyrax::SolrQueryService.new.with_ids(ids: ids).solr_documents

      documents.map { |doc| new(doc) }
    rescue RSolr::Error::ConnectionRefused
      []
    end

    ##
    # @api private
    # @deprecated use CatalogController.blacklight_config.document_model instead
    def self.document_model
      Deprecation
        .warn("Use CatalogController.blacklight_config.document_model instead.")
      CatalogController.blacklight_config.document_model
    end
    private_class_method :document_model
  end
end
