# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    ##
    # @api private
    #
    # The interface every m3 profile validator implements.
    #
    # A validator receives a {ValidationContext}, inspects the profile, and
    # records what it finds by calling {#add_error} or {#add_warning}. It does
    # not write to shared state; {Hyrax::FlexibleSchemaValidatorService}
    # collects each validator's {#violations} in registry order.
    #
    # @example Registering a custom validator
    #   class MyValidator < Hyrax::FlexibleSchemaValidators::BaseValidator
    #     def validate!
    #       properties.each do |name, config|
    #         add_warning(:my_key, property: name) if config['bad_thing']
    #       end
    #     end
    #   end
    #
    #   Hyrax.config.flexible_schema_validators += ['MyValidator']
    class BaseValidator
      ##
      # @param context [ValidationContext]
      def initialize(context)
        @context = context
      end

      ##
      # Inspect the profile, recording problems via {#add_error}/{#add_warning}.
      #
      # @abstract
      # @return [void]
      def validate!
        raise NotImplementedError, "#{self.class} must implement #validate!"
      end

      ##
      # @return [Array<Hyrax::ProfileViolation>] what this validator found
      def violations
        @violations ||= []
      end

      ##
      # The I18n scope this validator's message keys live under. Subclasses
      # nested inside another validator must override this, since the derived
      # name would otherwise be the inner constant alone.
      #
      # @return [String]
      def self.i18n_scope
        @i18n_scope ||= "hyrax.flexible_schema_validators.#{name.demodulize.underscore}"
      end

      private

      attr_reader :context

      delegate :profile, :schemer, :required_classes, :properties, :class_names, to: :context

      ##
      # @param key [Symbol, String] an I18n key under this validator's scope, or
      #   a literal message
      # @return [void]
      def add_error(key, **opts)
        violations << violation(:error, key, **opts)
      end

      ##
      # @see #add_error
      def add_warning(key, **opts)
        violations << violation(:warning, key, **opts)
      end

      def violation(severity, key, **opts)
        Hyrax::ProfileViolation.new(severity: severity, message: resolve(severity, key, **opts))
      end

      # A Symbol is looked up under this validator's scope; a String is already
      # the message. Validators predating the I18n convention pass strings, and
      # their wording is asserted verbatim by existing specs.
      def resolve(severity, key, **opts)
        return key.to_s unless key.is_a?(Symbol)

        I18n.t("#{self.class.i18n_scope}.#{severity}s.#{key}", **opts)
      end

      # Prepended so it sees the arguments before {#initialize} does. Delete the
      # module and this line together.
      prepend LegacyValidatorCompatibility
    end
  end
end
