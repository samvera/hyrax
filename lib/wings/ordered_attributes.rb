# frozen_string_literal: true

module Wings
  ##
  # Honors Valkyrie's `ordered` attribute meta for plain hash entries, which
  # Valkyrie's own Fedora adapter keeps in order natively. ActiveFedora stores a
  # property's values unordered, so each entry records its position on write
  # and the saved order is restored on read.
  module OrderedAttributes
    POSITION_KEY = '_position'

    ##
    # @param attributes [Hash{Symbol => Object}] a resource's attributes
    # @param resource_class [Class] the Valkyrie resource class
    # @return [Hash] the attributes, with positions added to ordered hash entries
    def self.encode(attributes, resource_class)
      attributes.to_h do |key, values|
        next [key, values] unless ordered?(resource_class, key) && hash_entries?(values)
        [key, values.each_with_index.map { |entry, index| entry.merge(POSITION_KEY => index) }]
      end
    end

    ##
    # @param attributes [Hash{Symbol => Object}] attributes read from ActiveFedora
    # @param resource_class [Class] the Valkyrie resource class
    # @return [Hash] the attributes, with ordered hash entries sorted and their
    #   positions removed
    def self.decode(attributes, resource_class)
      attributes.to_h do |key, values|
        next [key, values] unless ordered?(resource_class, key) && values.present?
        [key, restore_order(Array.wrap(values))]
      end
    end

    def self.restore_order(values)
      entries = values.map { |value| Hyrax::SchemaLoader::AttributeDefinition::JsonHash.call(value) }
      return values unless entries.any? { |entry| entry.is_a?(::Hash) && entry.key?(POSITION_KEY) }

      entries.each_with_index
             .sort_by { |entry, index| [entry.is_a?(::Hash) ? entry.fetch(POSITION_KEY, index).to_i : index, index] }
             .map { |entry, _index| entry.is_a?(::Hash) ? entry.except(POSITION_KEY) : entry }
    end
    private_class_method :restore_order

    def self.ordered?(resource_class, key)
      resource_class.schema.key(key.to_sym).type.meta[:ordered] ? true : false
    rescue StandardError
      false
    end
    private_class_method :ordered?

    def self.hash_entries?(values)
      values.is_a?(Array) && values.any? &&
        values.all? { |entry| entry.is_a?(::Hash) && !(entry.key?(:internal_resource) || entry.key?('internal_resource')) }
    end
    private_class_method :hash_entries?
  end
end
