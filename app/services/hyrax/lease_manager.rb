# frozen_string_literal: true

module Hyrax
  ##
  # Provides utilities for managing the lifecycle of an `Hyrax::Lease` on a
  # `Hyrax::Resource`.
  class LeaseManager
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
      def apply_lease_for(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .apply
      end

      def apply_lease_for!(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .apply!
      end

      def lease_for(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .lease
      end

      def release_lease_for(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .release
      end

      def release_lease_for!(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .release!
      end
    end

    ##
    # Copies and applies the lease to a new (target) resource.
    #
    # @param target [Hyrax::Resource]
    #
    # @return [Boolean]
    def copy_lease_to(target:)
      return false unless under_lease?

      target.lease = Lease.new(clone_attributes)
      self.class.apply_lease_for(resource: target)
    end

    ##
    # @return [Boolean]
    def apply
      return false unless under_lease?

      resource.visibility = lease.visibility_during_lease
    end

    ##
    # @return [void]
    # @raise [NotEnforcableError] when trying to apply an lease that isn't active
    def apply!
      apply || raise(NotEnforcableError)
    end

    ##
    # @return [Boolean]
    def enforced?
      lease.visibility_during_lease.to_s == resource.visibility
    end

    ##
    # @return [Hyrax::Lease]
    def lease
      resource.lease || Lease.new
    end

    ##
    # @return [Boolean]
    def release
      return false if under_lease?
      return true if lease.visibility_after_lease.nil?

      resource.visibility = lease.visibility_after_lease
    end

    ##
    # @return [void]
    def release!
      release || raise(NotReleasableError)
    end

    ##
    # @return [Boolean]
    def under_lease?
      lease.active?
    end

    class NotEnforcableError < RuntimeError; end
    class NotReleasableError < RuntimeError; end

    private

    def clone_attributes
      lease.attributes.slice(*core_attribute_keys)
    end

    def core_attribute_keys
      [:visibility_after_lease, :visibility_during_lease, :lease_expiration_date]
    end
  end
end
