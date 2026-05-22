# frozen_string_literal: true
module Hyrax
  # Shared rendering helpers for authority-backed values that may have been
  # stored as either a real URI or as free text (the M3 metadata profile, plus
  # bulk importers such as Bulkrax and Willow Sword, can both produce
  # free-text values that the UI's authority dropdown did not constrain).
  module AuthorityRenderingHelper
    # Schemes considered safe to emit in an `<a href>`. Anything else (notably
    # `javascript:`, `data:`, custom schemes, or non-absolute strings like
    # `"moomin"`) is rendered as plain text so it cannot be activated as a
    # link.
    LINKABLE_URI_SCHEMES = %w[http https].freeze

    module_function

    # @param value [String, nil]
    # @return [Boolean] true when the value parses as an absolute URI with an
    #   allowed scheme, suitable to use as an anchor's href.
    def linkable_uri?(value)
      return false if value.blank?

      parsed = URI.parse(value)
      parsed.absolute? && LINKABLE_URI_SCHEMES.include?(parsed.scheme&.downcase)
    rescue URI::InvalidURIError
      false
    end
  end
end
