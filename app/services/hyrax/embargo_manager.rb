# frozen_string_literal: true

module Hyrax
  ##
  # Manages an embargo for a `Hyrax::Resource`
  class EmbargoManager
    ##
    # @!attribute [rw] resource
    #   @return [Hyrax::Resource]
    attr_accessor :resource

    ##
    # @!attribute [r] query_service
    #   @return [#find_by]
    attr_reader :query_service

    ##
    # @param resource [Hyrax::Resource]
    def initialize(resource:, query_service: Hyrax.query_service)
      @query_service = query_service
      self.resource  = resource
    end

    ##
    # @return [Valkyrie::Resource]
    def embargo
      return Embargo::NullEmbargo.new unless resource.embargo_id.present?

      query_service.find_by(id: resource.embargo_id)
    end

    ##
    # @return [Boolean]
    def under_embargo?
      embargo.active?
    end
  end
end
