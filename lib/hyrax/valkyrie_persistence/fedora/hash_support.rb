# frozen_string_literal: true
require 'valkyrie/persistence/fedora'

# OVERRIDE Valkyrie v3.6.1 to store plain Hash attribute values on Fedora, mirroring samvera/valkyrie#1005
#   - NestedProperty stores a plain Hash as a nested graph
#   - arrays in a Hash are written as RDF lists, and an empty one as rdf:nil
#   - OrmConverter reads a stored Hash back as just its own keys
#   - an RDF list reads back as an Array, even with one value, and rdf:nil as []
#   - Applicator#cast_array uses Array.wrap, so merging a second value doesn't split a Hash
#
# Delete this file once Hyrax requires a Valkyrie release that includes #1005 (tracked in samvera/hyrax#7703).
module Hyrax
  module ValkyriePersistence
    module Fedora
      ModelConverter = ::Valkyrie::Persistence::Fedora::Persister::ModelConverter
      GraphToAttributes = ::Valkyrie::Persistence::Fedora::Persister::OrmConverter::GraphToAttributes

      # OVERRIDE (new): wraps a plain Hash so ModelConverter can convert it the
      # same way it converts a nested Valkyrie::Resource.
      class HashDummy
        INTERNAL_RESOURCE = "Valkyrie::InternalHash"

        attr_reader :hsh
        delegate :[], to: :hsh
        def initialize(hsh)
          @hsh = hsh
        end

        def attributes
          hsh
        end

        # A hash has no Fedora identity of its own; it lives under a hash URI
        # in its parent's graph.
        def id; end

        # Arrays in a Hash are written as RDF lists so they keep their order.
        def ordered_attribute?(key)
          hsh[key].is_a?(Array)
        end
      end

      module OrderedPropertiesClassOverride
        def ordered?(value)
          # OVERRIDE: a Hash says for itself which of its keys are ordered
          return value.resource.ordered_attribute?(value.key) if value.resource.is_a?(HashDummy)
          super
        end
      end

      # OVERRIDE (new): an empty Array in a Hash is written as rdf:nil, so it
      # reads back as an empty Array instead of being dropped.
      class EmptyHashArray < ::Valkyrie::ValueMapper
        def self.handles?(value)
          value.is_a?(ModelConverter::Property) && value.resource.is_a?(HashDummy) && value.value == []
        end

        def result
          ModelConverter::Property.new(value.subject, value.key, RDF.nil, value.adapter, value.resource)
        end
      end

      module NestedPropertyClassOverride
        # OVERRIDE: handle any Hash, not only one naming an internal_resource
        def handles?(value)
          value.is_a?(ModelConverter::Property) &&
            (value.value.is_a?(Hash) || value.value.is_a?(::Valkyrie::Resource))
        end
      end

      module NestedPropertyOverride
        def nested_graph
          # OVERRIDE: build the nested graph from #nested_resource
          @nested_graph ||= ModelConverter.new(resource: nested_resource, adapter: value.adapter, subject_uri: subject_uri).convert.graph
        end

        # OVERRIDE (new): a plain Hash (one without an internal_resource) is
        # stored as a nested graph marked with {HashDummy::INTERNAL_RESOURCE},
        # so the reader can tell it apart from a nested resource.
        def nested_resource
          return ::Valkyrie::Types::Anything[value.value] if value.value.is_a?(::Valkyrie::Resource) || value.value[:internal_resource]
          HashDummy.new(value.value.merge(internal_resource: HashDummy::INTERNAL_RESOURCE))
        end
      end

      module OrmConverterOverride
        def convert
          attrs = attributes
          # OVERRIDE: a stored plain Hash reads back as just its own keys
          return attrs.except(:id, :new_record, :internal_resource) if stored_hash?(attrs)
          populate_native_lock(::Valkyrie::Types::Anything[attrs])
        end

        # OVERRIDE (new)
        # @param [Hash] attrs
        # @return [Boolean]
        def stored_hash?(attrs)
          attrs[:internal_resource] == HashDummy::INTERNAL_RESOURCE
        end
      end

      # OVERRIDE (new): applies the values of an RDF list as an Array, even
      # when the list holds a single value
      class OrderedApplicator < GraphToAttributes::CompositeApplicator
        def initialize(applicators, key)
          super(applicators)
          @key = key.to_sym
        end

        def apply_to(hsh)
          super
          hsh[@key] = Array.wrap(hsh[@key]) if hsh.key?(@key)
          hsh
        end
      end

      module OrderedPropertyOverride
        def result
          values = ::Valkyrie::Persistence::Fedora::OrderedList.new(scope, head, tail, adapter).to_a.map(&:proxy_for)
          values = values.map do |val|
            calling_mapper.for(GraphToAttributes::Property.new(statement: RDF::Statement.new(value.statement.subject, value.statement.predicate, val),
                                                               scope: value.scope, adapter: value.adapter)).result
          end
          # OVERRIDE: OrderedApplicator, so a one-value list stays an Array
          OrderedApplicator.new(values, GraphToAttributes::Applicator.new(value).key)
        end
      end

      # OVERRIDE (new): maps an empty RDF list (rdf:nil) to an empty Array
      class EmptyListValue < ::Valkyrie::ValueMapper
        def self.handles?(value)
          value.statement.object == RDF.nil
        end

        def result
          EmptyListApplicator.new(value)
        end
      end

      # OVERRIDE (new)
      class EmptyListApplicator < GraphToAttributes::Applicator
        def apply_to(hsh)
          hsh[key.to_sym] = Array.wrap(hsh[key.to_sym]) unless deny?(key)
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

nested_property = Valkyrie::Persistence::Fedora::Persister::ModelConverter::NestedProperty
unless nested_property.const_defined?(:HashDummy, false)
  hash_support = Hyrax::ValkyriePersistence::Fedora
  model_converter = hash_support::ModelConverter
  graph_to_attributes = hash_support::GraphToAttributes

  nested_property.const_set(:HashDummy, hash_support::HashDummy)
  nested_property.singleton_class.prepend(hash_support::NestedPropertyClassOverride)
  nested_property.prepend(hash_support::NestedPropertyOverride)
  model_converter::OrderedProperties.singleton_class.prepend(hash_support::OrderedPropertiesClassOverride)
  hash_support.register_before(model_converter::FedoraValue, hash_support::EmptyHashArray, nested_property)

  Valkyrie::Persistence::Fedora::Persister::OrmConverter.prepend(hash_support::OrmConverterOverride)
  graph_to_attributes::OrderedProperty.prepend(hash_support::OrderedPropertyOverride)
  graph_to_attributes::Applicator.prepend(hash_support::ApplicatorOverride)
  hash_support.register_before(graph_to_attributes::FedoraValue, hash_support::EmptyListValue, graph_to_attributes::MemberID)
end
