# frozen_string_literal: true

# OVERRIDE Valkyrie v3.6.1 to read a stored plain Hash back as written on Postgres, mirroring samvera/valkyrie#1005
#
# Delete this file once Hyrax requires a Valkyrie release that includes #1005 (tracked in samvera/hyrax#7703).
module Hyrax
  module ValkyriePersistence
    module Shared
      # OVERRIDE (new): converts a stored Hash that is not a nested resource, with symbol keys.
      # Nested hashes are converted like any other value, but arrays are never
      # unwrapped and strings are never cast, so a plain Hash reads back exactly
      # as it was written.
      class PlainHashValue < ::Valkyrie::ValueMapper
        # Determines whether or not a value is a Hash that is not a nested resource
        # @param [Object] value
        # @return [Boolean]
        def self.handles?(value)
          value.is_a?(Hash) && !value.key?("internal_resource")
        end

        # @return [Hash]
        def result
          value.each_with_object({}) do |(key, val), result|
            result[key.to_sym] = map_value(val) unless val.nil?
          end
        end

        private

        def map_value(val)
          case val
          when Hash
            calling_mapper.for(val).result
          when Array
            val.map { |element| map_value(element) }
          else
            val
          end
        end
      end
    end
  end
end

json_value_mapper = Valkyrie::Persistence::Shared::JSONValueMapper
unless json_value_mapper.const_defined?(:PlainHashValue, false)
  json_value_mapper.const_set(:PlainHashValue, Hyrax::ValkyriePersistence::Shared::PlainHashValue)
  # OVERRIDE: register ahead of NestedRecord, the position it has in Valkyrie
  casters = json_value_mapper::PostgresValue.value_casters
  json_value_mapper::PostgresValue.value_casters =
    casters.dup.insert(casters.index(json_value_mapper::NestedRecord), Hyrax::ValkyriePersistence::Shared::PlainHashValue)
end
