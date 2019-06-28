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

    class << self
      def apply_embargo_for(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .apply
      end

      def embargo_for(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .embargo
      end
    end

    ##
    # @return [Hyrax::Embargo]
    def clone_embargo
      return Embargo::NullEmbargo.new unless under_embargo?

      Embargo.new(clone_attributes)
    end

    ##
    # @return [Boolean]
    def apply
      return false unless under_embargo?

      resource.visibility = embargo.visibility_during_embargo
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

    private

      def clone_attributes
        embargo.attributes.slice(*core_attribute_keys)
      end

      def core_attribute_keys
        [:visibility_after_embargo, :visibility_during_embargo, :embargo_release_date]
      end
  end
end
