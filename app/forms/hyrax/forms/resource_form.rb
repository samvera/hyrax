# frozen_string_literal: true

module Hyrax
  module Forms
    ##
    # @api public
    #
    # This form wraps +Hyrax::ChangeSet+ in the +HydraEditor::Form+ interface.
    class ResourceForm < Hyrax::ChangeSet # rubocop:disable Metrics/ClassLength
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

      include BasedNearFieldBehavior
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
      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def initialize(deprecated_resource = nil, resource: nil)
        r = resource || deprecated_resource
        if r.flexible?
          self.class.deserializer_class = nil # need to reload this on first use after schema is loaded
          singleton_class.schema_definitions = self.class.definitions
          contexts = r.respond_to?(:contexts) ? r.contexts : nil
          Hyrax::Schema.m3_schema_loader.form_definitions_for(schema: r.class.name, version: Hyrax::FlexibleSchema.current_schema_id, contexts: contexts).map do |field_name, options|
            singleton_class.property field_name.to_sym, options.merge(display: options.fetch(:display, true), default: [])
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
          # make a new resource with all of the existing attributes
          if resource.flexible?
            hash = resource.attributes.dup
            hash[:schema_version] = Hyrax::FlexibleSchema.current_schema_id
            resource = resource.class.new(hash)
            # find any fields removed by the new schema
            to_remove = singleton_class.definitions.select { |k, v| !resource.respond_to?(k) && v.instance_variable_get("@options")[:display] }
            to_remove.keys.each do |removed_field|
              singleton_class.definitions.delete(removed_field)
            end
          end

          super(resource)
        end
      end # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      class << self
        def inherited(subclass)
          # this is a noop if based near is not defined on a given model
          # we need these to be before and included properties
          subclass.prepend(BasedNearFieldBehavior)
          super
        end

        def check_if_flexible(model)
          return unless model.flexible?
          include FlexibleFormBehavior
          include Hyrax::FormFields(model.to_s, definition_loader: Hyrax::Schema.m3_schema_loader)
        end

        ##
        # @api public
        #
        # Factory for generic, per-work forms.
        #
        # When +admin_set_id+ is provided and the resource supports flexible metadata,
        # the admin set's contexts are applied to the resource before building the form
        # so that context-gated fields appear correctly.
        #
        # @example
        #   monograph  = Monograph.new
        #   change_set = Hyrax::Forms::ResourceForm.for(resource: monograph)
        #
        # @example with admin set context
        #   change_set = Hyrax::Forms::ResourceForm.for(resource: monograph, admin_set_id: '123')
        def for(deprecated_resource = nil, resource: nil, admin_set_id: nil)
          if resource.nil? && !deprecated_resource.nil?
            Deprecation.warn "Initializing Valkyrie forms without an explicit resource parameter is deprecated. Pass the resource with `resource:` instead."
            return self.for(resource: deprecated_resource, admin_set_id: admin_set_id)
          end
          apply_admin_set_contexts(resource: resource, admin_set_id: admin_set_id)
          klass = "#{resource.class.name}Form".safe_constantize
          klass ||= Hyrax::Forms::ResourceForm(resource.class)
          begin
            klass.new(resource: resource)
          rescue ArgumentError
            Deprecation.warn "Initializing Valkyrie forms without an explicit resource parameter is deprecated. #{klass} should be updated accordingly."
            klass.new(resource)
          end
        end

        private

        def apply_admin_set_contexts(resource:, admin_set_id:)
          return if admin_set_id.blank?
          return unless resource.respond_to?(:flexible?) && resource.flexible?
          admin_set = Hyrax.query_service.find_by(id: admin_set_id)
          return if admin_set.blank? || !admin_set.respond_to?(:contexts)
          contexts = Array(admin_set.contexts)
          resource.contexts = contexts if contexts.present?
        rescue Valkyrie::Persistence::ObjectNotFoundError
          nil
        end

        ##
        # @return [Array<Symbol>] list of required field names as symbols
        def required_fields
          schema_definitions
            .select { |_, definition| definition[:required] }
            .keys.map(&:to_sym)
        end

        ##
        # @param [Enumerable<#to_s>] fields
        #
        # @return [Array<Symbol>] list of required field names as symbols
        def required_fields=(fields)
          fields = fields.map(&:to_s)
          raise(KeyError) unless fields.all? { |f| schema_definitions.key?(f) }

          fields.each { |field| schema_definitions[field].merge!(required: true) }

          required_fields
        end

        def schema_definitions
          @definitions
        end

        def schema_definitions=(values)
          @definitions = values
        end

        def expose_class
          @expose_class = Class.new(Disposable::Expose).from(schema_definitions.values)
        end

        public :expose_class, :required_fields, :required_fields=, :schema_definitions, :schema_definitions=
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

        terms = [:schema_version, :contexts] + terms if model.flexible?
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

      delegate :flexible?, to: :model

      private

      def _form_field_definitions
        if model.flexible?
          singleton_class.schema_definitions
        else
          self.class.definitions
        end
      end
    end
  end
end
