# frozen_string_literal: true

module Hyrax
  ##
  # Provides utilities for managing the lifecycle of an `Hyrax::Embargo` on a
  # `Hyrax::Resource`.
  #
  # This can do things like
  #
  # @example check whether a resource is under an active embargo
  #   manager = EmbargoManager.new(resource: my_resource)
  #   manager.under_embargo? # => false
  #
  # @example applying an embargo
  #   embargo = Hyrax::Embargo.new(visibility_during_embargo: 'restricted',
  #                                visibility_after_embargo:  'open',
  #                                embargo_release_date:      Time.zone.today + 1000)
  #
  #   resource            = Hyrax::Resource.new(embargo: embargo)
  #   resource.visibility = 'open'
  #
  #   manager = EmbargoManager.new(resource: resource)
  #
  #   manager.apply
  #   resource.visibility # => 'restricted'
  #
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
    # Copies and applies the embargo to a new (target) resource.
    #
    # @param target [Hyrax::Resource]
    #
    # @return [Boolean]
    def copy_embargo_to(target:)
      return false unless under_embargo?

      target.embargo = Embargo.new(clone_attributes)
      self.class.apply_embargo_for(resource: target)
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
      resource.embargo || Embargo.new
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
