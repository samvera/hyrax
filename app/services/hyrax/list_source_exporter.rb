# frozen_string_literal: true
module Hyrax
  ##
  # @deprecated see Hyrax::GraphExporter::ListSourceExporter
  #
  # Retrieves the graph for an object with the internal triples removed
  # and the uris translated to external uris.
  class ListSourceExporter < GraphExporter::ListSourceExporter
    ##
    # @param [String] id
    # @param [ActionDispatch::Request] request the http request context
    # @param [String] parent_url
    # @param [String] hostname  the current http host
    def initialize(id, request, parent_url, hostname: nil)
      Deprecation.warn("#{subject.class} is deprecated and replaced with the (private) Hyrax::GraphExporter::")
      host = hostname || request.host
      super(id: id, parent_url: parent_url, hostname: host)
    end

    ##
    # @!attribute [r] request
    #   @deprecated use {#hostname} to access the host
    #   @return [ActionDispatch::Request]
    attr_reader :request
    deprecation_deprecate :request
  end
end
