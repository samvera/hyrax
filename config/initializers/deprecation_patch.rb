# frozen_string_literal: true
#
# OVERRIDE deprecation v1.1.0  – handle calls using either the deprecation gem method signature
#                                or newer Rails method signatues.
#                                see: https://github.com/samvera/hyrax/issues/7303
# Remove when: dependencies no longer pull in the deprecation gem

module Deprecation
  module DeprecationWarningPatch
    def warn(*args)
      # if the first argument being passed is a string,
      # the caller is using the Rails-style signature,
      # so we need to pass a dummy first argument to
      # the older gem method
      if args.first.is_a?(String)
        super(nil, *args)
      else
        super(*args)
      end
    end
  end
end

using_deprecation_gem = Object.const_source_location('Deprecation').first.match?('gems/deprecation')

# Only patch if we're using the separate deprecation gem
Deprecation.singleton_class.prepend(Deprecation::DeprecationWarningPatch) if using_deprecation_gem
