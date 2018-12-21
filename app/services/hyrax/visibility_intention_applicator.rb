# frozen_string_literal: true
module Hyrax
  ##
  # Applies a `VisibilityIntention` to a repository object.
  class VisibilityIntentionApplicator
    ##
    # @!attribute [rw] intention
    #   @return [VisibilityIntention]
    attr_accessor :intention

    ##
    # @param [VisibilityIntention] intention
    def initialize(intention:)
      self.intention = intention
    end

    ##
    # @param [VisibilityIntention] intention
    #
    # @return [VisibilityIntentionApplicator]
    def self.apply(intention)
      new(intention: intention)
    end

    ##
    # @param [Object] obj an object; this probably needs to be leasable,
    #   embargoable, has visibility, and an AdminSet/PermissionTemplate.
    def apply_to(obj)
      if intention.wants_embargo?
        raise InvalidIntentionError unless intention.valid_embargo?
        obj.apply_embargo(*intention.embargo_params)
      elsif intention.wants_lease?
        raise InvalidIntentionError unless intention.valid_lease?
        obj.apply_lease(*intention.lease_params)
      else
        obj.visibility = intention.visibility
      end
    end
    alias to apply_to

    class InvalidIntentionError < ArgumentError; end
  end
end
