# frozen_string_literal: true

require 'wings/converter_value_mapper'

module Wings
  # This needs to be reconciled with AttributeTransformer
  class ActiveFedoraAttributes
    attr_reader :attributes

    # Constructor
    # @param attributes [Hash]
    def initialize(attributes)
      @attributes = attributes
    end

    # Transforms attribues from Valkyrie Resources for ActiveFedora Models
    # @return [Hash]
    def result
      Hash[
        filtered_attributes.map do |value|
          ConverterValueMapper.for(value).result
        end.select(&:present?)
      ]
    end

    private

      # Filter for attributes which cannot be passed to ActiveFedora constructor
      # or attribute mutator methods
      # @return [Hash]
      # rubocop:disable Metrics/MethodLength
      def filtered_attributes
        # avoid reflections for now; `*_ids` can't be passed as attributes.
        # handling for reflections needs to happen in future work
        attrs = attributes.reject { |k, _| k.to_s.end_with? '_ids' }

        attrs.delete(:internal_resource)
        attrs.delete(:new_record)
        attrs.delete(:id)
        attrs.delete(:alternate_ids)
        attrs.delete(:created_at)
        attrs.delete(:updated_at)
        attrs.delete(:member_ids)
        attrs.delete(:read_groups)
        attrs.delete(:read_users)
        attrs.delete(:edit_groups)
        attrs.delete(:edit_users)

        embargo_id         = attrs.delete(:embargo_id)
        attrs[:embargo_id] = embargo_id.to_s unless embargo_id.nil? || embargo_id.empty?
        lease_id          = attrs.delete(:lease_id)
        attrs[:lease_id]  = lease_id.to_s unless lease_id.nil? || lease_id.empty?
        attrs.compact
      end
    # rubocop:enable Metrics/MethodLength
  end
end
