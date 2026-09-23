# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    ##
    # @api private
    #
    # Lets validators written against the pre-registry interface keep working.
    # Everything here is temporary; see {BaseValidator} for the current one.
    #
    # Two older habits are supported:
    #
    # 1. **Constructing a validator with the profile and the message arrays**,
    #    e.g. `new(profile, errors)` or `new(profile:, errors:, warnings:)`.
    #    This warns, and the arrays passed in are still filled.
    # 2. **Appending to `@errors` or `@warnings`** from an overridden
    #    `#validate!`. This does *not* warn: a downstream decorator that
    #    prepends an override has no other way to record what it finds, so the
    #    ivars outlive the deprecated constructor above.
    #
    # To remove: delete this file, drop the `include` and the `super()` guard
    # from {BaseValidator#initialize}, and replace any remaining
    # `@errors <<` / `@warnings <<` in Hyrax's own validators with
    # `add_error` / `add_warning`.
    module LegacyValidatorCompatibility
      ##
      # Accepts either a {ValidationContext} or one of the older argument lists,
      # and installs the `@errors` / `@warnings` collectors either way.
      def initialize(*args, **kwargs)
        if args.first.is_a?(ValidationContext) && args.one? && kwargs.empty?
          super(args.first)
        else
          context, @legacy_errors, @legacy_warnings = coerce_legacy_arguments(args, kwargs)
          super(context)
        end

        @errors = Collector.new(self, :error)
        @warnings = Collector.new(self, :warning)
      end

      private

      # Mirror into the array an older caller passed in. {BaseValidator} records
      # the violation itself, so these only add the copy.
      def add_error(key, **opts)
        super
        @legacy_errors << violations.last.message if @legacy_errors
      end

      # @see #add_error
      def add_warning(key, **opts)
        super
        @legacy_warnings << violations.last.message if @legacy_warnings
      end

      # Maps an older argument list onto a {ValidationContext}. Each validator
      # took some arrangement of the profile, the arrays to append to, and
      # occasionally `required_classes` or the JSON schemer.
      #
      # @return [Array(ValidationContext, Array, Array)]
      def coerce_legacy_arguments(args, kwargs)
        Hyrax.deprecator.warn(
          "#{self.class}.new with the profile and message arrays is deprecated; pass a " \
          "Hyrax::FlexibleSchemaValidators::ValidationContext instead, and read the results " \
          "from #violations. Register custom validators with " \
          "Hyrax.config.flexible_schema_validators."
        )

        # The one older signature leading with something other than the profile.
        schemer = args.shift if args.first.respond_to?(:validate) && !args.first.is_a?(Hash)

        profile = kwargs[:profile] || args.shift
        required_classes = args.first.is_a?(Array) && args.size > 1 ? args.shift : nil
        errors = kwargs.fetch(:errors, args.shift) || []
        warnings = kwargs.fetch(:warnings, args.shift) || []

        [ValidationContext.new(profile: profile, schemer: schemer, required_classes: required_classes),
         errors, warnings]
      end

      ##
      # @api private
      #
      # Stands in for the plain message array a validator used to be handed.
      # Appending records a violation of one severity on the validator, so
      # `@errors << 'message'` and `add_error('message')` are the same call.
      class Collector
        def initialize(validator, severity)
          @validator = validator
          @severity = severity
        end

        # Routed through the validator so an appended message is recorded and
        # mirrored exactly as `add_error` / `add_warning` would do it.
        def <<(message)
          @validator.send(@severity == :error ? :add_error : :add_warning, message)
          self
        end
      end
    end
  end
end
