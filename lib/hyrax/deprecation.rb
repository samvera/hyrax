# frozen_string_literal: true

module Hyrax
  # Provides version-specific deprecators for Hyrax
  #
  # @example Standard usage for next major version
  #   Hyrax.deprecator.warn("This will be removed in Hyrax 6.0")
  #
  # @example Specific version targeting
  #   Hyrax.deprecator(7).warn("This will be removed in Hyrax 7.0")
  #
  # @example Marking technical debt
  #   Hyrax.deprecator(4).warn("This should have been removed in Hyrax 4.0")
  def self.deprecator(major_version = nil)
    @deprecators ||= {}

    # Default to next major version if not specified
    major_version ||= 6 # Update this when 6.0 is released

    @deprecators[major_version] ||= begin
      dep = ActiveSupport::Deprecation.new("#{major_version}.0", "Hyrax")
      dep.behavior = Rails.application.config.active_support.deprecation
      dep
    end
  end

  # Alias for backwards compatibility
  def self.deprecation
    deprecator
  end
end
