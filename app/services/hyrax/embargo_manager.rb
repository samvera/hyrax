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
  #    - "Released" means the embargo's post-release visibility has been set on
  #      the resource.
  #    - "Enforced" means the object's visibility matches the pre-release
  #      visibility of the embargo; i.e. the embargo has been applied,
  #      but not released.
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

      def apply_embargo_for!(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .apply!
      end

      def embargo_for(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .embargo
      end

      def release_embargo_for(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .release
      end

      def release_embargo_for!(resource:, query_service: Hyrax.query_service)
        new(resource: resource, query_service: query_service)
          .release!
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
      embargo.visibility_during_embargo.to_s == resource.visibility
    end

    ##
    # @return [Hyrax::Embargo]
    def embargo
      resource.embargo || Embargo.new
    end

    ##
    # Sets the visibility of the resource to the embargo's visibility condition.
    # no-op if the embargo period is current.
    #
    # @return [Boolean] truthy if the embargo has been applied
    def release
      return false if under_embargo?
      return true if embargo.visibility_after_embargo.nil?

      resource.visibility = embargo.visibility_after_embargo
    end

    ##
    # @return [void]
    # @raise [NotEnforcableError] when trying to release an embargo that
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
  end
end
