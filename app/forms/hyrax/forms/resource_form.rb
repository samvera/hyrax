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

        (work_class.fields - work_class.reserved_attributes).each do |field|
          property field, default: nil
        end
      end
    end

    ##
    # @api public
    #
    # This form wraps `Hyrax::ChangeSet` in the `HydraEditor::Form` interface.
    class ResourceForm < Hyrax::ChangeSet
      class_attribute :model_class

      delegate :human_readable_type, to: :model

      property :visibility # visibility has an accessor on the model

      property :agreement_accepted, virtual: true, default: false, prepopulator: ->(_opts) { self.agreement_accepted = !model.new_record }

      # virtual properties for embargo/lease;
      property :embargo_release_date, virtual: true, prepopulator: ->(_opts) { self.embargo_release_date = embargo&.embargo_release_date }
      property :visibility_after_embargo, virtual: true, prepopulator: ->(_opts) { self.visibility_after_embargo = embargo&.visibility_after_embargo }
      property :visibility_during_embargo, virtual: true, prepopulator: ->(_opts) { self.visibility_during_embargo = embargo&.visibility_during_embargo }

      property :lease_expiration_date, virtual: true,  prepopulator: ->(_opts) { self.lease_expiration_date = lease&.lease_expiration_date }
      property :visibility_after_lease, virtual: true, prepopulator: ->(_opts) { self.visibility_after_lease = lease&.visibility_after_lease }
      property :visibility_during_lease, virtual: true, prepopulator: ->(_opts) { self.visibility_during_lease = lease&.visibility_during_lease }

      class << self
        ##
        # @api public
        #
        # Factory for generic, per-work froms
        #
        # @example
        #   monograph  = Monograph.new
        #   change_set = Hyrax::Forms::ResourceForm.for(monograph)
        def for(work)
          Hyrax::Forms::ResourceForm(work.class).new(work)
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

      def primary_terms
        []
      end

      def secondary_terms
        []
      end

      def display_additional_fields?
        secondary_terms.any?
      end
    end
  end
end
