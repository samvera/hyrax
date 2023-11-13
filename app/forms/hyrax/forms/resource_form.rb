# frozen_string_literal: true

module Hyrax
  module Forms
    ##
    # @api public
    #
    # Returns the form class associated with a given model.
    def self.ResourceForm(model_class) # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
      @resource_forms ||= {}.compare_by_identity
      @resource_forms[model_class] ||=
        # +#respond_to?+ needs to be used here, not +#try+, because Dry::Types
        # overrides the latter??
        if model_class.respond_to?(:pcdm_collection?) && model_class.pcdm_collection?
          if model_class <= Hyrax::AdministrativeSet
            Hyrax.config.administrative_set_form
          else
            Hyrax.config.pcdm_collection_form
          end
        elsif model_class.respond_to?(:pcdm_object?) && model_class.pcdm_object?
          if model_class.respond_to?(:file_set?) && model_class.file_set?
            Hyrax.config.file_set_form
          else
            Hyrax.config.pcdm_object_form_builder.call(model_class)
          end
        else
          Hyrax::Forms::ResourceForm
        end
    end

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

      class << self
        ##
        # @api public
        #
        # Factory for generic, per-work froms
        #
        # @example
        #   monograph  = Monograph.new
        #   change_set = Hyrax::Forms::ResourceForm.for(monograph)
        def for(resource)
          klass = "#{resource.class.name}Form".safe_constantize
          klass ||= Hyrax::Forms::ResourceForm(resource.class)
          klass.new(resource)
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
        _form_field_definitions
          .select { |_, definition| definition[:primary] }
          .keys.map(&:to_sym)
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

      private

      def _form_field_definitions
        self.class.definitions
      end
    end
  end
end
