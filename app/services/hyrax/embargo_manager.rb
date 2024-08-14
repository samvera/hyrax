# frozen_string_literal: true

module Hyrax
  ##
  # Provides utilities for managing the lifecycle of an `Hyrax::Embargo` on a
  # `Hyrax::Resource`.
  #
  # The embargo terminology used here is as follows:
  #
  #    - "Release Date" is the day an embargo is scheduled to be released.
  #    - "Under Embargo" means the embargo is "active"; i.e. that its release
  #       date is today or later.
  #    - "Applied" means the embargo's pre-release visibility has been set on
  #      the resource.
  #    - "Enforced" means the object's visibility matches the pre-release
  #      visibility of the embargo; i.e. the embargo has been applied,
  #      but not released.
  #    - "Released" means the embargo's post-release visibility has been set on
  #      the resource.
  #    - "Deactivate" means that the existing embargo will be removed, even
  #      if it active.
  #
  # Note that an resource may be `#under_embargo?` even if the embargo is not
  # be `#enforced?` (in this case, the application should seek to apply the
  # embargo, e.g. via a scheduled job). Additionally, an embargo may be
  # `#enforced?` after its release date (in this case, the application should
  # seek to release the embargo).
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
  #   manager.apply!
  #   manager.enforced? => true
  #   resource.visibility # => 'restricted'
  #
  # @example releasing an embargo
  #   embargo = Hyrax::Embargo.new(visibility_during_embargo: 'restricted',
  #                                visibility_after_embargo:  'open',
  #                                embargo_release_date:      Time.zone.today + 1000)
  #
  # @example releasing an embargo
  #   embargo = Hyrax::Embargo.new(visibility_during_embargo: 'restricted',
  #                                visibility_after_embargo:  'open',
  #                                embargo_release_date:      Time.zone.today + 1)
  #
  #   resource = Hyrax::Resource.new(embargo: embargo)
  #   manager  = EmbargoManager.new(resource: resource)
  #
  #   manager.under_embargo? => true
  #   manager.enforced? => false
  #
  #   manager.apply!
  #
  #   resource.visibility # => 'restricted'
  #   manager.enforced? => true
  #
  #   manager.release! # => NotReleasableError
  #
  #   # <spongebob narrator>ONE DAY LATER</spongebob narrator>
  #   manager.under_embargo? => false
  #   manager.enforced? => true
  #
  #   manager.release!
  #
  #   resource.visibility # => 'open'
  #   manager.enforced? => false
  #
  class EmbargoManager # rubocop:disable Metrics/ClassLength
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

      def apply_embargo_for!(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .apply!
      end

      def embargo_for(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .embargo
      end

      # @return [Boolean]
      def deactivate_embargo_for(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .deactivate
      end

      # @return [Boolean]
      def deactivate_embargo_for!(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .deactivate!
      end

      # @return [Boolean]
      def release_embargo_for(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .release
      end

      # @return [Boolean]
      def release_embargo_for!(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .release!
      end

      # Creates or updates an existing embargo on a member to match the embargo on the parent work
      # @param [Array<Valkyrie::Resource>] members
      # @param [Hyrax::Work] work
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def create_or_update_embargo_on_members(members, work)
        # TODO: account for all members and levels, not just file sets. ref: #6131
        members.each do |member|
          # reload member to make sure nothing in the transaction has changed it already
          member = Hyrax.query_service.find_by(id: member.id)
          member_embargo_needs_updating = work.embargo.updated_at > member.embargo&.updated_at if member.embargo

          if member.embargo && member_embargo_needs_updating
            member.embargo.embargo_release_date = work.embargo['embargo_release_date']
            member.embargo.visibility_during_embargo = work.embargo['visibility_during_embargo']
            member.embargo.visibility_after_embargo = work.embargo['visibility_after_embargo']
            member.embargo = Hyrax.persister.save(resource: member.embargo)
          else
            work_embargo_manager = Hyrax::EmbargoManager.new(resource: work)
            work_embargo_manager.copy_embargo_to(target: member)
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

    ##
    # Deactivates the embargo
    # @return [Boolean]
    def deactivate
      release(force: true) &&
        nullify(force: true)
    end

    ##
    # Deactivates the embargo
    # @return [Boolean]
    def deactivate!
      release(force: true)
      nullify(force: true)
    end

    ##
    # Copies and applies the embargo to a new (target) resource.
    #
    # @param target [Hyrax::Resource]
    #
    # @return [Boolean]
    def copy_embargo_to(target:)
      return false unless under_embargo?

      target.embargo = Hyrax.persister.save(resource: Embargo.new(clone_attributes))
      self.class.apply_embargo_for(resource: target)
    end

    ##
    # Sets the visibility of the resource to the embargo's visibility condition
    #
    # @return [Boolean]
    def apply
      return false unless under_embargo?

      resource.visibility = embargo.visibility_during_embargo
    end

    ##
    # @return [void]
    # @raise [NotEnforcableError] when trying to apply an embargo that isn't active
    def apply!
      apply || raise(NotEnforcableError)
    end

    ##
    # @return [Boolean]
    def enforced?
      embargo.embargo_release_date.present? &&
        (embargo.visibility_during_embargo.to_s == resource.visibility)
    end

    ##
    # @return [Hyrax::Embargo]
    def embargo
      resource.embargo || Embargo.new
    end

    ##
    # Drop the embargo by setting its release date and visibility settings to `nil`.
    #
    # @param force [Boolean] force the nullify even when the embargo period is current
    #
    # @return [Boolean]
    def nullify(force: false)
      return false if !force && under_embargo?

      embargo.embargo_release_date = nil
      embargo.visibility_during_embargo = nil
      embargo.visibility_after_embargo = nil
      true
    end

    ##
    # Sets the visibility of the resource to the embargo's after embargo visibility.
    # no-op if the embargo period is current and the force flag is false.
    #
    # @param force [boolean] force the release even when the embargo period is current
    #
    # @return [Boolean] truthy if the embargo has been applied
    def release(force: false)
      return false if !force && under_embargo?

      embargo_state = embargo.active? ? 'active' : 'expired'
      history_record = embargo_history_message(
        embargo_state,
        Hyrax::TimeService.time_in_utc,
        embargo.embargo_release_date,
        embargo.visibility_during_embargo,
        embargo.visibility_after_embargo
      )
      embargo.embargo_history += [history_record]

      return true if embargo.visibility_after_embargo.nil?

      resource.visibility = embargo.visibility_after_embargo
    end

    ##
    # @return [void]
    # @raise [NotReleasableError] when trying to release an embargo that
    #   is currently active
    def release!
      release || raise(NotReleasableError)
    end

    ##
    # @return [Boolean] indicates whether the date range for the embargo's
    #   applicability includes the present date.
    def under_embargo?
      embargo.active?
    end

    class NotEnforcableError < RuntimeError; end
    class NotReleasableError < RuntimeError; end

    private

    def clone_attributes
      embargo.attributes.slice(*core_attribute_keys)
    end

    def core_attribute_keys
      [:visibility_after_embargo, :visibility_during_embargo, :embargo_release_date]
    end

    protected

    # Create the log message used when releasing an embargo
    def embargo_history_message(state, deactivate_date, release_date, visibility_during, visibility_after)
      I18n.t 'hydra.embargo.history_message',
              state: state,
              deactivate_date: deactivate_date,
              release_date: release_date,
              visibility_during: visibility_during,
              visibility_after: visibility_after
    end
  end
end
