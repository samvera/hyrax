# frozen_string_literal: true

module Hyrax
  ##
  # Defends compound attributes (`type: hash, multiple: true` with `subproperties:` —
  # see {Hyrax::CompoundSchema}) against a read-path quirk in Valkyrie's Postgres
  # orm_converter: `JSONValueMapper` unwraps a single-element array to its first
  # element and re-symbolizes the Hash's keys, then dry-struct's `Array.of(Hash)`
  # coercion calls `Array(hash)`, splaying it into pairs. Net effect: a saved
  # `[{a: 1, b: 2}]` reads back as `[[:a, 1], [:b, 2]]`.
  #
  # The compound list comes from the effective schema, so the defense works in
  # both flex modes. Include this on a resource whose schema declares compounds.
  module CompoundNormalization
    extend ActiveSupport::Concern

    # Prepended onto the host class's singleton so it pre-normalizes compound
    # attrs before dry-struct's strict coercion runs. (In flex mode `.new` routes
    # through Hyrax::Flexibility#load; the instance write path covers that.)
    module ClassOverrides
      def new(attrs = {}, *args)
        names = (respond_to?(:compound_attribute_names) ? compound_attribute_names : [])
        attrs = Hyrax::CompoundNormalization.normalize_attrs(attrs, names) if attrs.is_a?(::Hash) && names.any?
        super
      end
    end

    included do
      singleton_class.prepend(ClassOverrides)
    end

    class_methods do
      def compound_attribute_names
        @compound_attribute_names ||= Hyrax::CompoundSchema.for(self).compound_names
      rescue StandardError
        []
      end
    end

    def compound_attribute_names
      @compound_attribute_names ||= Hyrax::CompoundSchema.for(self).compound_names
    rescue StandardError
      []
    end

    def set_value(key, value)
      value = Hyrax::CompoundNormalization.normalize_compound(value) if compound_attribute_names.include?(key.to_sym)
      super(key, value)
    end

    # @api private
    def self.normalize_attrs(attrs, compound_names)
      attrs = attrs.dup
      compound_names.each do |key|
        [key, key.to_s].each do |k|
          attrs[k] = normalize_compound(attrs[k]) if attrs.key?(k)
        end
      end
      attrs
    end

    # @api private
    def self.normalize_compound(value)
      return value if value.nil?
      arr = value.is_a?(::Array) ? value : [value]
      arr = collapse_pair_array(arr) || collapse_flat_pair(arr) || arr
      arr.map { |entry| entry.is_a?(::Hash) ? entry.transform_keys(&:to_s) : entry }
    end

    # Rebuild entries from an array of [key, value] pairs. Pairs arrive two
    # different ways and need different repairs:
    #
    # * ONE entry with several fields, splayed apart:
    #   `[[:a, 1], [:b, 2]]` -> `[{a: 1, b: 2}]`
    # * SEVERAL entries with one field each, each unwrapped to its pair:
    #   `[[:a, 1], [:a, 2]]` -> `[{a: 1}, {a: 2}]`
    #
    # A repeated key is the tell: one splayed entry can never repeat a key, so
    # repeats always mean "one entry per pair". Merging those into a single
    # hash would quietly keep only the last value - saving two contributors
    # with just names and getting one back. When every key is distinct the two
    # origins are indistinguishable here, so keep the single-entry reading
    # (the far more common shape). Returns nil if the input doesn't look like
    # a pair array.
    def self.collapse_pair_array(arr)
      return nil if arr.empty?
      return nil unless arr.all? { |e| pair?(e) }
      return arr.map { |pair| ::Hash[[pair]] } if arr.map { |pair| pair.first.to_s }.uniq.length < arr.length
      [::Hash[arr]]
    end

    # Single-key collapse: `["a", 1]` -> `[{"a" => 1}]`. Returns nil if the
    # input doesn't look like a single flat pair.
    def self.collapse_flat_pair(arr)
      return nil unless arr.length == 2
      return nil unless arr.first.is_a?(::Symbol) || arr.first.is_a?(::String)
      return nil if arr.last.is_a?(::Hash) || arr.last.is_a?(::Array)
      [::Hash[[arr]]]
    end

    def self.pair?(element)
      element.is_a?(::Array) &&
        element.length == 2 &&
        (element.first.is_a?(::Symbol) || element.first.is_a?(::String))
    end
  end
end
