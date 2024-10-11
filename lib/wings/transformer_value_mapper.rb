# frozen_string_literal: true

module Wings
  ##
  # A base value mapper for converting property values in the
  # `ActiveFedora`/`ActiveTriples` type system to `Valkyrie` types
  #
  # This top level matcher has registered several internal mappers which handle
  # indivdual value types from the source data.
  class TransformerValueMapper < ::Valkyrie::ValueMapper; end

  class NestedResourceMapper < ::Valkyrie::ValueMapper
    # needs to register before the ResourceMapper or it will use that one
    # instead
    TransformerValueMapper.register(self)

    def self.handles?(value)
      value.is_a? Wings::ActiveFedoraConverter::NestedResource
    end

    def result
      attributes = value.attributes.symbolize_keys
      nested_object = Wings::ActiveFedoraConverter::NestedResource.new(attributes)
      klass = Wings::ModelTransformer::ResourceClassCache.instance.fetch(Wings::ActiveFedoraConverter::NestedResource) do
        OrmConverter.to_valkyrie_resource_class(klass: nested_object.class)
      end
      klass.new(attributes)
    end
  end

  ##
  # Maps `RDF::Term` values to their underlying types.
  #
  # Most importantly, this handles cases where a complex model implementing
  # `RDF::Term` (e.g. an `ActiveFedora::Base` or `ActiveTriples::RDFSource`) is
  # included as a value, casting it to an `RDF::URI` or `RDF::Node` which can be
  # handled by `Valkyrie`.
  #
  # @see RDF::Term
  class ResourceMapper < ::Valkyrie::ValueMapper
    TransformerValueMapper.register(self)

    ##
    # @param value [Object]
    #
    # @return [Boolean]
    def self.handles?(value)
      value.respond_to?(:term?) && value.term?
    end

    ##
    # Valkyrie objects contain a URI string for location objects so we need
    # to return just the string for mapping from Fedora
    #
    # @return [RDF::Term || String]
    def result
      return value.id if value.is_a?(Hyrax::ControlledVocabularies::Location)
      value.to_term
    end
  end

  ##
  # Maps enumerable values (e.g. Array, Enumerable, Hash, etc...) by calling the
  # parent `ValueMapper` on each member.
  #
  # @note a common value type this mapper handles is `ActiveTriples::Relation`
  class EnumerableMapper < ::Valkyrie::ValueMapper
    TransformerValueMapper.register(self)

    ##
    # @param value [Object]
    def self.handles?(value)
      value.is_a?(Enumerable)
    end

    ##
    # @return [Enumerable<Object>]
    def result
      return calling_mapper.for(value.first).result if value.length < 2
      value.map { |v| calling_mapper.for(v).result }
    end
  end
end
