# frozen_string_literal: true

module Hyrax
  ##
  # Provides utilities for managing the lifecycle of an `Hyrax::Lease` on a
  # `Hyrax::Resource`.
  #
  # The lease terminology used here is as follows:
  #
  #    - "Expiration Date" is the day a lease is scheduled to expire.
  #    - "Under Lease" means the lease is "active"; i.e. that its expiration
  #       date is today or later.
  #    - "Applied" means the lease's pre-expiration visibility has been set on
  #      the resource.
  #    - "Released" means the lease's post-expiration visibility has been set on
  #      the resource.
  #    - "Enforced" means the object's visibility matches the pre-expiration
  #      visibility of the lease; i.e. the lease has been applied,
  #      but not released.
  #    - "Deactivate" means that the existing lease will be removed
  #
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

    # Deactivates the lease and logs a message to the lease_history property
    def deactivate!
      lease_state = lease.active? ? 'active' : 'expired'
      lease_record = lease_history_message(
        lease_state,
        Time.zone.today,
        lease.lease_expiration_date,
        lease.visibility_during_lease,
        lease.visibility_after_lease
      )

      release(force: true)
      nullify(force: true)
      lease.lease_history += [lease_record]
    end

    ##
    # Copies and applies the lease to a new (target) resource.
    #
    # @param target [Hyrax::Resource]
    #
    # @return [Boolean]
    def copy_lease_to(target:)
      return false unless under_lease?

      target.lease = Hyrax.persister.save(resource: Lease.new(clone_attributes))
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
      lease.lease_expiration_date.present? &&
        lease.visibility_during_lease.to_s == resource.visibility
    end

    ##
    # @return [Hyrax::Lease]
    def lease
      resource.lease || Lease.new
    end

    ##
    # Drop the lease by setting its release date and visibility settings to `nil`.
    #
    # @param force [boolean] force the nullify even when the lease period is current
    # @return [void]
    def nullify(force: false)
      return false if !force && under_lease?

      lease.lease_expiration_date = nil
      lease.visibility_during_lease = nil
      lease.visibility_after_lease = nil
    end

    ##
    # Sets the visibility of the resource to the lease's after lease visibility.
    # no-op if the lease period is current and the force flag is false.
    #
    # @param force [boolean] force the release even when the lease period is current
    #
    # @return [Boolean]
    def release(force: false)
      return false if !force && under_lease?
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

    protected

    # Create the log message used when deactivating a lease
    def lease_history_message(state, deactivate_date, expiration_date, visibility_during, visibility_after)
      I18n.t 'hydra.lease.history_message',
              state: state,
              deactivate_date: deactivate_date,
              expiration_date: expiration_date,
              visibility_during: visibility_during,
              visibility_after: visibility_after
    end
  end
end
