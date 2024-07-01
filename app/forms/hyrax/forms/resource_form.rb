# frozen_string_literal: true

module Hyrax
  module Forms
    ##
    # @api public
    #
    # This form wraps +Hyrax::ChangeSet+ in the +HydraEditor::Form+ interface.
    class ResourceForm < Hyrax::ChangeSet # rubocop:disable Metrics/ClassLength
      # These do not get auto loaded when using a flexible schema and should instead
      # be added to the individual Form classes for a work type or smart enough
      # to be selective as to when they trigger
      include BasedNearFieldBehavior if Hyrax.config.flexible?

      ##
      # @api private
      #
      # @note includes special handling for Wings, to support compatibility
      #   with `etag`-driven, application-side lock checks. for non-wings adapters
      #   we want to move away from application side lock validation and rely
      #   on the adapter/database features instead.
      LockKeyPrepopulator = proc do |_options|
        if Hyrax.config.disable_wings || !Hyrax.metadata_adapter.is_a?(Wings::Valkyrie::MetadataAdapter)
          Hyrax.logger.info "trying to prepopulate a lock token for " \
                            "#{self.class.inspect}, but optimistic locking isn't " \
                            "supported for the configured adapter: #{Hyrax.metadata_adapter.class}"
          self.version = ''
        else
          self.version =
            model.persisted? ? Wings::ActiveFedoraConverter.convert(resource: model).etag : ''
        end
      end

      class_attribute :model_class

      property :human_readable_type, writable: false
      property :date_modified, readable: false
      property :date_uploaded, readable: false

      # provide a lock token for optimistic locking; we name this `version` for
      # backwards compatibility
      #
      # Hyrax handles lock token validation on the application side for legacy
      # models and Wings so we provide a token even if optimistic locking on
      # the model is disabled
      #
      # @see https://github.com/samvera/valkyrie/wiki/Optimistic-Locking
      property :version, virtual: true, prepopulator: LockKeyPrepopulator

      ##
      # @api public
      #
      # Forms should be initialized with an explicit +resource:+ parameter to
      # match indexers.
      def initialize(deprecated_resource = nil, resource: nil) # rubocop:disable Metrics/MethodLength
        if Hyrax.config.flexible?
          singleton_class.instance_variable_set("@definitions", self.class.definitions)
          r = resource || deprecated_resource
          Hyrax::Schema.default_schema_loader.form_definitions_for(schema: r.class.to_s, version: r.schema_version).map do |field_name, options|
            singleton_class.property field_name.to_sym, options.merge(display: options.fetch(:display, true), default: [])
            singleton_class.validates field_name.to_sym, presence: true if options.fetch(:required, false)
          end
        end

        if resource.nil?
          if !deprecated_resource.nil?
            Deprecation.warn "Initializing Valkyrie forms without an explicit resource parameter is deprecated. Pass the resource with `resource:` instead."
            super(deprecated_resource)
          else
            super()
          end
        else
          super(resource)
        end
      end # rubocop:enable Metrics/MethodLength

      class << self
        ##
        # @api public
        #
        # Factory for generic, per-work froms
        #
        # @example
        #   monograph  = Monograph.new
        #   change_set = Hyrax::Forms::ResourceForm.for(resource: monograph)
        def for(deprecated_resource = nil, resource: nil)
          if resource.nil? && !deprecated_resource.nil?
            Deprecation.warn "Initializing Valkyrie forms without an explicit resource parameter is deprecated. Pass the resource with `resource:` instead."
            return self.for(resource: deprecated_resource)
          end
          klass = "#{resource.class.name}Form".safe_constantize
          klass ||= Hyrax::Forms::ResourceForm(resource.class)
          begin
            klass.new(resource: resource)
          rescue ArgumentError
            Deprecation.warn "Initializing Valkyrie forms without an explicit resource parameter is deprecated. #{klass} should be updated accordingly."
            klass.new(resource)
          end
        end

        ##
        # @return [Array<Symbol>] list of required field names as symbols
        def required_fields
          definitions
            .select { |_, definition| definition[:required] }
            .keys.map(&:to_sym)
        end

        ##
        # @param [Enumerable<#to_s>] fields
        #
        # @return [Array<Symbol>] list of required field names as symbols
        def required_fields=(fields)
          fields = fields.map(&:to_s)
          raise(KeyError) unless fields.all? { |f| definitions.key?(f) }

          fields.each { |field| definitions[field].merge!(required: true) }

          required_fields
        end
      end

      ##
      # @param [#to_s] attr
      # @param [Object] value
      #
      # @return [Object] the set value
      def []=(attr, value)
        public_send("#{attr}=".to_sym, value)
      end

      ##
      # @deprecated use model.class instead
      #
      # @return [Class]
      def model_class # rubocop:disable Rails/Delegate
        model.class
      end

      ##
      # @return [Array<Symbol>] terms for display 'above-the-fold', or in the most
      #   prominent form real estate
      def primary_terms
        terms = _form_field_definitions
                .select { |_, definition| definition[:primary] }
                .keys.map(&:to_sym)

        terms = [:schema_version] + terms if Hyrax.config.flexible?
        terms
      end

      ##
      # @return [Array<Symbol>] terms for display 'below-the-fold'
      def secondary_terms
        _form_field_definitions
          .select { |_, definition| definition[:display] && !definition[:primary] }
          .keys.map(&:to_sym)
      end

      ##
      # @return [Boolean] whether there are terms to display 'below-the-fold'
      def display_additional_fields?
        secondary_terms.any?
      end

      # OVERRIDE disposable 0.6.3 to make schema dynamic
      def schema
        if Hyrax.config.flexible?
          Definition::Each.new(singleton_class.definitions)
        else
          super
        end
      end

      private

      # OVERRIDE valkyrie 3.0.1 to make schema dynamic
      def field(field_name)
        if Hyrax.config.flexible?
          singleton_class.definitions.fetch(field_name.to_s)
        else
          super
        end
      end

      def _form_field_definitions
        if Hyrax.config.flexible?
          singleton_class.definitions
        else
          self.class.definitions
        end
      end
    end
  end
end
