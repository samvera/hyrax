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
      include FlexibleFormBehavior if Hyrax.config.flexible?

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
      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def initialize(deprecated_resource = nil, resource: nil)
        if Hyrax.config.flexible?
          singleton_class.schema_definitions = self.class.definitions
          r = resource || deprecated_resource
          Hyrax::Schema.default_schema_loader.form_definitions_for(schema: r.class.to_s, version: Hyrax::FlexibleSchema.current_schema_id, contexts: r.contexts).map do |field_name, options|
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
          # make a new resource with all of the existing attributes
          if Hyrax.config.flexible?
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

        terms = [:schema_version, :contexts] + terms if Hyrax.config.flexible?
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

      def validate(params)
        process_based_near_params(params) if Hyrax.config.flexible? && params.key?(:based_near_attributes)

        super(params)
      end

      private

      def process_based_near_params(params)
        based_near_attributes = params.delete(:based_near_attributes)
        return unless based_near_attributes.respond_to?(:each_pair)

        uris_from_form = []
        based_near_attributes.each do |_, h|
          next unless h.respond_to?(:[])
          next if h["_destroy"] == "true" || h["id"].blank?
          begin
            uris_from_form << RDF::URI.parse(h["id"]).to_s
          rescue ArgumentError, TypeError, RDF::ReaderError
            Rails.logger.warn("Invalid URI ignored during form processing: #{h['id']}")
          end
        end
        params[:based_near] = uris_from_form.uniq
      end

      def _form_field_definitions
        if Hyrax.config.flexible?
          singleton_class.schema_definitions
        else
          self.class.definitions
        end
      end
    end
  end
end
