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
    # @note The returned class will extend +Hyrax::Forms::PcdmObjectForm+, not
    #   only +Hyrax::Forms::ResourceForm+. This is for backwards‐compatibility
    #   with existing Hyrax instances and satisfies the expected general use
    #   case (building forms for various PCDM object classes), but is *not*
    #   necessarily suitable for other kinds of Hyrax resource, like
    #   +Hyrax::FileSet+s.
    def self.ResourceForm(work_class)
      Class.new(Hyrax::Forms::PcdmObjectForm) do
        self.model_class = work_class

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
    # This form wraps +Hyrax::ChangeSet+ in the +HydraEditor::Form+ interface.
    class ResourceForm < Hyrax::ChangeSet # rubocop:disable Metrics/ClassLength
      ##
      # @api private
      InWorksPrepopulator = proc do |_options|
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

      property :depositor

      property :visibility, default: VisibilityIntention::PRIVATE, populator: :visibility_populator

      property :date_modified, readable: false
      property :date_uploaded, readable: false
      property :agreement_accepted, virtual: true, default: false, prepopulator: proc { |_opts| self.agreement_accepted = !model.new_record }

      collection(:permissions,
                 virtual: true,
                 default: [],
                 form: Hyrax::Forms::Permission,
                 populator: :permission_populator,
                 prepopulator: proc { |_opts| self.permissions = Hyrax::AccessControl.for(resource: model).permissions })

      property :embargo, form: Hyrax::Forms::Embargo, populator: :embargo_populator
      property :lease, form: Hyrax::Forms::Lease, populator: :lease_populator

      # virtual properties for embargo/lease;
      property :embargo_release_date, virtual: true, prepopulator: proc { |_opts| self.embargo_release_date = model.embargo&.embargo_release_date }
      property :visibility_after_embargo, virtual: true, prepopulator: proc { |_opts| self.visibility_after_embargo = model.embargo&.visibility_after_embargo }
      property :visibility_during_embargo, virtual: true, prepopulator: proc { |_opts| self.visibility_during_embargo = model.embargo&.visibility_during_embargo }

      property :lease_expiration_date, virtual: true,  prepopulator: proc { |_opts| self.lease_expiration_date = model.lease&.lease_expiration_date }
      property :visibility_after_lease, virtual: true, prepopulator: proc { |_opts| self.visibility_after_lease = model.lease&.visibility_after_lease }
      property :visibility_during_lease, virtual: true, prepopulator: proc { |_opts| self.visibility_during_lease = model.lease&.visibility_during_lease }

      property :in_works_ids, virtual: true, prepopulator: InWorksPrepopulator

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
          "#{resource.class.name}Form".constantize.new(resource)
        rescue NameError => _err
          case resource
          when Hyrax::AdministrativeSet
            Hyrax::Forms::AdministrativeSetForm.new(resource)
          when Hyrax::FileSet
            Hyrax::Forms::FileSetForm.new(resource)
          when Hyrax::PcdmCollection
            Hyrax::Forms::PcdmCollectionForm.new(resource)
          else
            # NOTE: This will create a +Hyrax::Forms::PcdmObjectForm+.
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

      def embargo_populator(**)
        self.embargo = Hyrax::EmbargoManager.embargo_for(resource: model)
      end

      def lease_populator(**)
        self.lease = Hyrax::LeaseManager.lease_for(resource: model)
      end

      # https://trailblazer.to/2.1/docs/reform.html#reform-populators-populator-collections
      def permission_populator(collection:, index:, **)
        Hyrax::Forms::Permission.new(collection[index])
      end

      def visibility_populator(fragment:, doc:, **)
        case fragment
        when "embargo"
          self.visibility = doc['visibility_during_embargo']

          doc['embargo'] = doc.slice('visibility_after_embargo',
                                     'visibility_during_embargo',
                                     'embargo_release_date')
        when "lease"
          self.visibility = doc['visibility_during_lease']
          doc['lease'] = doc.slice('visibility_after_lease',
                                     'visibility_during_lease',
                                     'lease_expiration_date')
        else
          self.visibility = fragment
        end
      end

      def _form_field_definitions
        self.class.definitions
      end
    end
  end
end
