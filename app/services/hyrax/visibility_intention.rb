# frozen_string_literal: true
module Hyrax
  ##
  # Provides tools for interpreting form input as a visibility.
  #
  # @since 3.0.0
  class VisibilityIntention
    PUBLIC          = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    PRIVATE         = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    LEASE_REQUEST   = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE
    EMBARGO_REQUEST = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO

    ##
    # @!attribute [rw] after
    #   @return [String] the visibility requested after the embargo/lease release
    # @!attribute [rw] during
    #   @return [String] the visibility requested while the embargo/lease is in effect
    # @!attribute [rw] release_date
    #   @return [String]
    # @!attribute [rw] visibility
    #   @return [String]
    attr_accessor :after, :during, :release_date, :visibility

    ##
    # @param [String] after
    # @param [String] during
    # @param [String] release_date
    # @param [String] visibility
    def initialize(visibility: PRIVATE, release_date: nil, during: nil, after: nil)
      self.after        = after
      self.during       = during
      self.release_date = release_date
      self.visibility   = visibility
    end

    ##
    # @return [Array] the parameters for the requested embargo
    def embargo_params
      return []           unless wants_embargo?
      raise ArgumentError unless valid_embargo?

      [release_date, (during || PRIVATE), (after || PUBLIC)]
    end

    ##
    # @return [Array] the parameters for the requested embargo
    def lease_params
      return []           unless wants_lease?
      raise ArgumentError unless valid_lease?

      [release_date, (during || PUBLIC), (after || PRIVATE)]
    end

    ##
    # @return [Boolean]
    def valid_embargo?
      wants_embargo? && release_date.present? && a_valid_date?(release_date)
    end

    ##
    # @return [Boolean]
    def wants_embargo?
      visibility == EMBARGO_REQUEST
    end

    ##
    # @return [Boolean]
    def valid_lease?
      wants_lease? && release_date.present? && a_valid_date?(release_date)
    end

    ##
    # @return [Boolean]
    def wants_lease?
      visibility == LEASE_REQUEST
    end

    private

    ##
    # @param date [Object]
    # @return [Boolean]
    # @note If we don't have a valid date, we really can't have a
    # valid release_date
    def a_valid_date?(date)
      return true if date.is_a?(Date)
      return true if date.is_a?(Time)
      Date.parse(date)
    rescue Date::Error
      false
    end
  end
end
