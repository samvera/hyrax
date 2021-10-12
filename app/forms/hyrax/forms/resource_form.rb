# frozen_string_literal: true

module Hyrax
  module Forms
    ##
    # @api public
    #
    # @example defining a form class using HydraEditor-like configuration
    #   class MonographForm < Hyrax::Forms::ResourceForm(Monograph)
    #     self.required_fields = [:title, :creator, :rights_statement]
    #     # other WorkForm-like configuration here
    #   end
    #
    def self.ResourceForm(work_class)
      Class.new(Hyrax::Forms::ResourceForm) do
        self.model_class = work_class

        include Hyrax::FormFields(:core_metadata)

        ##
        # @return [String]
        def self.inspect
          return "Hyrax::Forms::ResourceForm(#{model_class})" if name.blank?
          super
        end
      end
    end

    ##
    # @api public
    #
    # This form wraps `Hyrax::ChangeSet` in the `HydraEditor::Form` interface.
    class ResourceForm < Hyrax::ChangeSet # rubocop:disable Metrics/ClassLength
      ##
      # @api private
      InWorksPopulator = lambda do |_options|
        self.in_works_ids =
          if persisted?
            Hyrax.query_service
                 .find_inverse_references_by(resource: model, property: :member_ids)
                 .select(&:work?)
                 .map(&:id)
          else
            []
          end
      end

      ##
      # @api private
      #
      # @note includes special handling for Wings, to support compatibility
      #   with `etag`-driven, application-side lock checks. for non-wings adapters
      #   we want to move away from application side lock validation and rely
      #   on the adapter/database features instead.
      LockKeyPopulator = lambda do |_options|
        self.version =
          case Hyrax.metadata_adapter
          when Wings::Valkyrie::MetadataAdapter
            model.persisted? ? Wings::ActiveFedoraConverter.convert(resource: model).etag : ''
          else
            Hyrax.logger.info 'trying to prepopulate a lock token for ' \
                              "#{self.class.inspect}, but optimistic locking isn't " \
                              "supported for the configured adapter: #{Hyrax.metadata_adapter.class}"
            ''
          end
      end

      class_attribute :model_class

      property :human_readable_type, writable: false

      property :depositor
      property :on_behalf_of
      property :proxy_depositor

      property :visibility, default: VisibilityIntention::PRIVATE

      property :date_modified, readable: false
      property :date_uploaded, readable: false
      property :agreement_accepted, virtual: true, default: false, prepopulator: ->(_opts) { self.agreement_accepted = !model.new_record }

      collection(:permissions,
                 virtual: true,
                 default: [],
                 form: Hyrax::Forms::Permission,
                 populator: :permission_populator,
                 prepopulator: ->(_opts) { self.permissions = Hyrax::AccessControl.for(resource: model).permissions })

      # virtual properties for embargo/lease;
      property :embargo_release_date, virtual: true, prepopulator: ->(_opts) { self.embargo_release_date = model.embargo&.embargo_release_date }
      property :visibility_after_embargo, virtual: true, prepopulator: ->(_opts) { self.visibility_after_embargo = model.embargo&.visibility_after_embargo }
      property :visibility_during_embargo, virtual: true, prepopulator: ->(_opts) { self.visibility_during_embargo = model.embargo&.visibility_during_embargo }

      property :lease_expiration_date, virtual: true,  prepopulator: ->(_opts) { self.lease_expiration_date = model.lease&.lease_expiration_date }
      property :visibility_after_lease, virtual: true, prepopulator: ->(_opts) { self.visibility_after_lease = model.lease&.visibility_after_lease }
      property :visibility_during_lease, virtual: true, prepopulator: ->(_opts) { self.visibility_during_lease = model.lease&.visibility_during_lease }

      # pcdm relationships
      property :admin_set_id, prepopulator: ->(_opts) { self.admin_set_id = AdminSet::DEFAULT_ID }
      property :in_works_ids, virtual: true, prepopulator: InWorksPopulator
      property :member_ids, default: [], type: Valkyrie::Types::Array
      property :member_of_collection_ids, default: [], type: Valkyrie::Types::Array

      property :representative_id, type: Valkyrie::Types::String
      property :thumbnail_id, type: Valkyrie::Types::String
      property :rendering_ids, default: [], type: Valkyrie::Types::Array

      # provide a lock token for optimistic locking; we name this `version` for
      # backwards compatibility
      #
      # Hyrax handles lock token validation on the application side for legacy
      # models and Wings so we provide a token even if optimistic locking on
      # the model is disabled
      #
      # @see https://github.com/samvera/valkyrie/wiki/Optimistic-Locking
      property :version, virtual: true, prepopulator: LockKeyPopulator

      # backs the child work search element;
      # @todo: look for a way for the view template not to depend on this
      property :find_child_work, default: nil, virtual: true

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
          "#{resource.class.name}Form".constantize.new(resource)
        rescue NameError => _err
          case resource
          when Hyrax::FileSet
            Hyrax::Forms::FileSetForm.new(resource)
          when Hyrax::PcdmCollection
            Hyrax::Forms::PcdmCollectionForm.new(resource)
          else
            Hyrax::Forms::ResourceForm(resource.class).new(resource)
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

      # https://trailblazer.to/2.1/docs/reform.html#reform-populators-populator-collections
      def permission_populator(collection:, index:, **)
        Hyrax::Forms::Permission.new(collection[index])
      end

      def _form_field_definitions
        self.class.definitions
      end
    end
  end
end
