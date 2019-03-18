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
    TransformerValueMapper.register(self)

    def self.handles?(value)
      value.is_a? Wings::ActiveFedoraConverter::NestedResource
    end

    def result
      id = ActiveFedora::Base.uri_to_id(value.id)
      obj = ActiveFedora::Base.find id
      attributes = obj.attributes.keys.each_with_object({}) do |attr_name, mem|
        mem[attr_name.to_sym] = TransformerValueMapper.for(obj.public_send(attr_name)).result
      end
      object = Wings::ActiveFedoraConverter::NestedResource.new(attributes)
      klass = Wings::ModelTransformer::ResourceClassCache.new.fetch(Wings::ActiveFedoraConverter::NestedResource) do
        ModelTransformer.to_valkyrie_resource_class(klass: object.class)
      end
      resource = klass.new(attributes)
      resource
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
    # @return [RDF::Term]
    def result
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
      value.map { |v| calling_mapper.for(v).result }
    end
  end
end
