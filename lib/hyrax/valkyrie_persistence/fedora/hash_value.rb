# frozen_string_literal: true
require 'valkyrie/persistence/fedora'

module Hyrax
  module ValkyriePersistence
    module Fedora
      # OVERRIDE Valkyrie v3.6.1
      #   - write each plain hash value as one `valkyrie_hash` typed JSON literal
      #   - read those literals back as their JSON string
      #
      # Valkyrie's Fedora `ModelConverter` has no mapper for a Hash that is not
      # a nested resource, so `Property#to_graph` splays it into stringified
      # `[key, value]` literals that cannot be read back as the original entry.
      # The datatype follows Valkyrie's own `valkyrie_bool`/`valkyrie_int`
      # convention, so native Hash support in Valkyrie (samvera/valkyrie#725)
      # could read this stored form as-is. The reader returns the JSON string
      # rather than a Hash because Valkyrie's `Applicator#cast_array` would splay
      # a Hash when merging a second value; `type: hash` attributes parse the
      # string (see {Hyrax::SchemaLoader::AttributeDefinition}).
      DATATYPE = ::Valkyrie::Persistence::Fedora::PermissiveSchema.uri_for(:valkyrie_hash)

      class HashValue < ::Valkyrie::Persistence::Fedora::Persister::ModelConverter::MappedFedoraValue
        ::Valkyrie::Persistence::Fedora::Persister::ModelConverter::FedoraValue.register(self)

        def self.handles?(value)
          value.is_a?(::Valkyrie::Persistence::Fedora::Persister::ModelConverter::Property) &&
            value.value.is_a?(::Hash) &&
            !(value.value.key?(:internal_resource) || value.value.key?('internal_resource'))
        end

        def result
          map_value(converted_value: RDF::Literal.new(value.value.to_json, datatype: DATATYPE))
        end
      end

      class HashLiteralValue < ::Valkyrie::ValueMapper
        ::Valkyrie::Persistence::Fedora::Persister::OrmConverter::GraphToAttributes::FedoraValue.register(self)

        def self.handles?(value)
          value.statement.object.is_a?(RDF::Literal) && value.statement.object.datatype == DATATYPE
        end

        def result
          value.statement.object = value.statement.object.value
          calling_mapper.for(
            ::Valkyrie::Persistence::Fedora::Persister::OrmConverter::GraphToAttributes::Property.new(
              statement: value.statement, scope: value.scope, adapter: value.adapter
            )
          ).result
        end
      end
    end
  end
end
