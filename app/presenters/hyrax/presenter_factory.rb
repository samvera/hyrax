# frozen_string_literal: true
module Hyrax
  # Responsible building an Array of presenters based on IDs and presenter class given
  # @todo Extract a SolrDocument finder class that takes a list of pids and returns/yields a ::SolrDocument for each hit in SOLR.
  # @note The given IDs are loaded from SOLR
  class PresenterFactory
    class << self
      # @todo Convert to find and yield only the found SOLR documents. There is a coupling of knowledge regarding the building of the presenter class and its parameters.
      # @todo We are looping through SOLR docs three times; Can this be compressed into a single loop
      #
      # @param [Array] ids the list of ids to load
      # @param [Class] presenter_class the class of presenter to make
      # @param [Array] presenter_args any other arguments to pass to the presenters
      # @return [Array] presenters for the documents in order of the ids (as given)
      def build_for(ids:, presenter_class:, presenter_args: [])
        new(ids: ids, presenter_class: presenter_class, presenter_args: presenter_args).build
      end
    end

    attr_reader :ids, :presenter_class, :presenter_args

    def initialize(ids:, presenter_class:, presenter_args:)
      @ids = ids
      @presenter_class = presenter_class
      # In moving from splat args to named parameters, passing the parameters is a bit off.
      @presenter_args = presenter_args.nil? ? [nil] : presenter_args
    end

    def build
      return [] if ids.blank?
      docs = load_docs
      ids.map do |id|
        solr_doc = docs.find { |doc| doc.id == id }
        presenter_class.new(solr_doc, *presenter_args) if solr_doc
      end.compact
    end

    private

    # @return [Array<SolrDocument>] a list of solr documents in no particular order
    def load_docs
      query("{!terms f=id}#{ids.join(',')}", rows: 1000)
        .map { |res| ::SolrDocument.new(res) }
    end

    # Query solr using POST so that the query doesn't get too large for a URI
    def query(query, **opts)
      result = Hyrax::SolrService.post(query, **opts)
      result.fetch('response').fetch('docs')
    end
  end
end
