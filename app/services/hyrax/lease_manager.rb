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
  #    - "Enforced" means the object's visibility matches the pre-expiration
  #      visibility of the lease; i.e. the lease has been applied,
  #      but not released.
  #    - "Released" means the leases's post-release visibility has been set on
  #      the resource.
  #    - "Deactivate" means that the existing lease will be removed, even if it
  #      is active
  #
  class LeaseManager # rubocop:disable Metrics/ClassLength
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

      # @return [Boolean]
      def deactivate_lease_for(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .deactivate
      end

      # @return [Boolean]
      def deactivate_lease_for!(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .deactivate!
      end

      # @return [Boolean]
      def release_lease_for(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .release
      end

      # @return [Boolean]
      def release_lease_for!(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .release!
      end

      # Creates or updates an existing lease on a member to match the lease on the parent work
      # @param [Array<Valkyrie::Resource>] members
      # @param [Hyrax::Work] work
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def create_or_update_lease_on_members(members, work)
        # TODO: account for all members and levels, not just file sets. ref: #6131

        members.each do |member|
          member_lease_needs_updating = work.lease.updated_at > member.lease&.updated_at if member.lease

          if member.lease && member_lease_needs_updating
            member.lease.lease_expiration_date = work.lease['lease_expiration_date']
            member.lease.visibility_during_lease = work.lease['visibility_during_lease']
            member.lease.visibility_after_lease = work.lease['visibility_after_lease']
            member.lease = Hyrax.persister.save(resource: member.lease)
          else
            work_lease_manager = Hyrax::LeaseManager.new(resource: work)
            work_lease_manager.copy_lease_to(target: member)
            member = Hyrax.persister.save(resource: member)
          end

          user ||= ::User.find_by_user_key(member.depositor)
          # the line below works in that it indexes the file set with the necessary lease properties
          # I do not know however if this is the best event_id to pass
          Hyrax.publisher.publish('object.metadata.updated', object: member, user: user)
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
    end

    def deactivate
      release(force: true) &&
        nullify(force: true)
    end

    # Deactivates the lease and logs a message to the lease_history property
    def deactivate!
      release(force: true)
      nullify(force: true)
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
    # @param force [Boolean] force the nullify even when the lease period is current
    # @return [Boolean]
    def nullify(force: false)
      return false if !force && under_lease?

      lease.lease_expiration_date = nil
      lease.visibility_during_lease = nil
      lease.visibility_after_lease = nil
      true
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

      lease_state = lease.active? ? 'active' : 'expired'
      history_record = lease_history_message(
        lease_state,
        Hyrax::TimeService.time_in_utc,
        lease.lease_expiration_date,
        lease.visibility_during_lease,
        lease.visibility_after_lease
      )

      lease.lease_history += [history_record]

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

    # Create the log message used when releasing a lease
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
