# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # @param [Symbol] schema_name
  #
  # @since 3.0.0
  def self.FormFields(schema_name, **options)
    Hyrax::FormFields.new(schema_name, **options)
  end

  ##
  # @api private
  #
  # @see .FormFields
  class FormFields < Module
    attr_reader :name, :version, :contexts

    ##
    # @api private
    #
    # @param [Symbol] schema_name
    # @param [#form_definitions_for] definition_loader
    #
    # @note use Hyrax::FormFields(:my_schema) instead
    def initialize(schema_name, definition_loader: SimpleSchemaLoader.new, version: 1, contexts: nil)
      @contexts = contexts
      @definition_loader = definition_loader
      @name = schema_name
      @version = version
    end

    ##
    # @return [Hash{Symbol => Hash{Symbol => Object}}]
    def form_field_definitions
      @definition_loader.form_definitions_for(schema: name, version:, contexts:)
    end

    ##
    # @return [String]
    def inspect
      "#{self.class}(#{@name})"
    end

    private

    # Full attribute config per field — carries keys beyond `form:` (e.g.
    # `subfields:`), unlike form_field_definitions.
    def attribute_configs
      @definition_loader.attributes_for(schema: name, version:, contexts:)
    end

    # @return [Boolean] whether the named field declares `subfields:`.
    def compound_field?(configs, field_name)
      type = configs[field_name.to_sym] || configs[field_name.to_s]
      meta = type.respond_to?(:meta) ? type.meta : {}
      meta.with_indifferent_access['subfields'].present?
    rescue StandardError
      false
    end

    # rubocop:disable Metrics/MethodLength
    def included(descendant)
      super
      return if @definition_loader.is_a?(Hyrax::M3SchemaLoader)
      configs = attribute_configs
      form_field_definitions.each do |field_name, options|
        descendant.property field_name.to_sym, options.merge(display: options.fetch(:display, true), default: [])
        descendant.validates field_name.to_sym, presence: true if options.fetch(:required, false)
        # A compound also needs a virtual `<field>_attributes` populator
        # property, registered here so it is part of Reform's schema before
        # `validate` runs (cf. Hyrax::RedirectsFieldBehavior).
        next unless compound_field?(configs, field_name)
        descendant.property :"#{field_name}_attributes",
                            virtual: true,
                            populator: :compound_attributes_populator
      end
      # Auto include any matching FormFieldBehaviors
      schema_name = name.to_s.camelcase
      behavior = "#{schema_name}FormFieldsBehavior".safe_constantize ||
                 "Hyrax::#{schema_name}FormFieldsBehavior".safe_constantize
      return unless behavior
      warning = <<-WARN
        Auto including a FormFieldsBehavior class based on name of the schema is depreciated.
        We are removing it from Hyrax as it has proven hard to debug or trace.
        Please include form field behaviors in your form classes directly.
      WARN
      Deprecation.warn warning
      descendant.include(behavior)
    end
    # rubocop:enable Metrics/MethodLength
  end
end
