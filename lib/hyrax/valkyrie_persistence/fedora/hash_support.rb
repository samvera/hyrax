# frozen_string_literal: true
require 'valkyrie/persistence/fedora'

# OVERRIDE Valkyrie v3.6.1 to store plain Hash attribute values on Fedora, mirroring samvera/valkyrie#1005
#   - PermissiveSchema.valkyrie_json is the datatype for a Hash stored as JSON
#   - ModelConverter writes a plain Hash as one RDF literal holding its JSON, without nil Hash values
#   - OrmConverter reads that literal back as a Hash with symbol keys
#   - Applicator#cast_array uses Array.wrap, so merging a second value doesn't split a Hash
#
# Delete this file once Hyrax requires a Valkyrie release that includes samvera/valkyrie#1005 (tracked in samvera/hyrax#7703).
module Hyrax
  module ValkyriePersistence
    module Fedora
      ModelConverter = ::Valkyrie::Persistence::Fedora::Persister::ModelConverter
      GraphToAttributes = ::Valkyrie::Persistence::Fedora::Persister::OrmConverter::GraphToAttributes

      module PermissiveSchemaOverride
        # OVERRIDE (new): the datatype for a Hash stored as JSON
        # @return [RDF::URI]
        def valkyrie_json
          uri_for(:valkyrie_json)
        end
      end

      # OVERRIDE (new): writes a plain Hash (one that is not a nested resource)
      # as a typed RDF literal holding the Hash as JSON
      class ModelJSONValue < ModelConverter::MappedFedoraValue
        def self.handles?(value)
          value.is_a?(ModelConverter::Property) && value.value.is_a?(Hash) && !value.value[:internal_resource]
        end

        def result
          map_value(converted_value: RDF::Literal.new(
            without_nil_values(value.value).to_json,
            datatype: ::Valkyrie::Persistence::Fedora::PermissiveSchema.valkyrie_json
          ))
        end

        private

        # Drops nil Hash values at every level, as the Postgres and Solr adapters do when reading
        def without_nil_values(val)
          case val
          when Hash
            val.each_with_object({}) { |(key, element), result| result[key] = without_nil_values(element) unless element.nil? }
          when Array
            val.map { |element| without_nil_values(element) }
          else
            val
          end
        end
      end

      # OVERRIDE (new): reads an RDF literal typed as JSON back as a Hash with
      # symbol keys
      class GraphJSONValue < ::Valkyrie::ValueMapper
        def self.handles?(value)
          value.statement.object.is_a?(RDF::Literal) &&
            value.statement.object.datatype == ::Valkyrie::Persistence::Fedora::PermissiveSchema.valkyrie_json
        end

        def result
          value.statement.object = JSON.parse(value.statement.object.value, symbolize_names: true)
          GraphToAttributes::Applicator.new(value)
        end
      end

      module ApplicatorOverride
        def cast_array(values)
          # OVERRIDE: Array.wrap, since Array() splits a Hash into pairs
          Array.wrap(values)
        end
      end

      # Registers a mapper ahead of an existing one, the position it has in Valkyrie.
      def self.register_before(registry, mapper, existing)
        casters = registry.value_casters
        registry.value_casters = casters.dup.insert(casters.index(existing), mapper)
      end
    end
  end
end

model_converter = Valkyrie::Persistence::Fedora::Persister::ModelConverter
unless model_converter.const_defined?(:JSONValue, false)
  hash_support = Hyrax::ValkyriePersistence::Fedora
  graph_to_attributes = hash_support::GraphToAttributes

  model_converter.const_set(:JSONValue, hash_support::ModelJSONValue)
  Valkyrie::Persistence::Fedora::PermissiveSchema.singleton_class.prepend(hash_support::PermissiveSchemaOverride)
  hash_support.register_before(model_converter::FedoraValue, hash_support::ModelJSONValue, model_converter::EnumerableValue)
  hash_support.register_before(graph_to_attributes::FedoraValue, hash_support::GraphJSONValue, graph_to_attributes::BooleanValue)
  graph_to_attributes::Applicator.prepend(hash_support::ApplicatorOverride)
end
