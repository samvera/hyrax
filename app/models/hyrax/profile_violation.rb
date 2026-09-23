# frozen_string_literal: true

module Hyrax
  ##
  # @api private
  #
  # One problem found in an m3 metadata profile.
  #
  # Severity rides on the violation rather than on the validator that produced
  # it: a single validator may emit either, depending on runtime state. See
  # {Hyrax::FlexibleSchemaValidators::RedirectsValidator}, which errors or warns
  # for the same profile depending on whether the redirects feature is enabled.
  ProfileViolation = Struct.new(:severity, :message, keyword_init: true) do
    ##
    # @return [Boolean] whether this violation blocks the profile from saving
    def error?
      severity == :error
    end

    ##
    # @return [Boolean]
    def warning?
      severity == :warning
    end
  end
end
