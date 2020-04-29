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
    end
  end
end
