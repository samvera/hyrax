# frozen_string_literal: true

module Hyrax
  module Forms
    ##
    # @api public
    # @see https://github.com/samvera/valkyrie/wiki/ChangeSets-and-Dirty-Tracking
    class PcdmCollectionForm < Valkyrie::ChangeSet
      property :title, required: true, primary: true

      property :depositor
      property :collection_type_gid

      class << self
        def model_class
          Hyrax::PcdmCollection
        end

        ##
        # @return [Array<Symbol>] list of required field names as symbols
        def required_fields
          definitions
            .select { |_, definition| definition[:required] }
            .keys.map(&:to_sym)
        end
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
