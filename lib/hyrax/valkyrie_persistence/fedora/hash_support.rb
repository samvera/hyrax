# frozen_string_literal: true
require 'valkyrie/persistence/fedora'

# OVERRIDE Valkyrie v3.6.1 to store plain Hash attribute values on Fedora, mirroring samvera/valkyrie#1005
#   - NestedProperty stores a plain Hash as a nested graph, built from a copy of the Hash
#   - OrmConverter reads a stored Hash back as just its own keys
#   - Applicator#cast_array uses Array.wrap, so merging a second value doesn't split a Hash
#
# Delete this file once Hyrax requires a Valkyrie release that includes #1005.
module Hyrax
  module ValkyriePersistence
    module Fedora
      class HashDummy
        INTERNAL_RESOURCE = "Valkyrie::InternalHash"

        # The converter asks every resource which attributes are ordered; a
        # hash has none.
        def self.attribute_names
          []
        end
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
      end

      module NestedPropertyClassOverride
        # OVERRIDE: handle any Hash, not only one naming an internal_resource
        def handles?(value)
          value.is_a?(::Valkyrie::Persistence::Fedora::Persister::ModelConverter::Property) &&
            (value.value.is_a?(Hash) || value.value.is_a?(::Valkyrie::Resource))
        end
      end

      module NestedPropertyOverride
        def nested_graph
          # OVERRIDE: build the nested graph from #nested_resource
          @nested_graph ||= ::Valkyrie::Persistence::Fedora::Persister::ModelConverter
                            .new(resource: nested_resource, adapter: value.adapter, subject_uri: subject_uri).convert.graph
        end

        # OVERRIDE (new): a plain Hash (one without an internal_resource) is
        # stored as a nested graph marked with {HashDummy::INTERNAL_RESOURCE},
        # built from a copy so the caller's Hash is left untouched.
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

      module ApplicatorOverride
        def cast_array(values)
          # OVERRIDE: Array.wrap, since Array() splits a Hash into pairs
          Array.wrap(values)
        end
      end
    end
  end
end

nested_property = Valkyrie::Persistence::Fedora::Persister::ModelConverter::NestedProperty
unless nested_property.const_defined?(:HashDummy, false)
  nested_property.const_set(:HashDummy, Hyrax::ValkyriePersistence::Fedora::HashDummy)
  nested_property.singleton_class.prepend(Hyrax::ValkyriePersistence::Fedora::NestedPropertyClassOverride)
  nested_property.prepend(Hyrax::ValkyriePersistence::Fedora::NestedPropertyOverride)
  Valkyrie::Persistence::Fedora::Persister::OrmConverter.prepend(Hyrax::ValkyriePersistence::Fedora::OrmConverterOverride)
  Valkyrie::Persistence::Fedora::Persister::OrmConverter::GraphToAttributes::Applicator
    .prepend(Hyrax::ValkyriePersistence::Fedora::ApplicatorOverride)
end
