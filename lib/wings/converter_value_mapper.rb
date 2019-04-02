# frozen_string_literal: true

require 'wings/nested_resource'
require 'wings/active_fedora_attributes'

module Wings
  ##
  # A base value mapper for converting property values in the
  # `Valkyrie` type system to `ActiveFedora`/`ActiveTriples` type
  #
  # This top level matcher has registered several internal mappers which handle
  # indivdual value types from the source data.
  class ConverterValueMapper < ::Valkyrie::ValueMapper; end

  class NestedResourceArrayValue < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)
    def self.handles?(value)
      value.is_a?(Array) && value.last.is_a?(Array) && value.last.map { |x| x.try(:class) }.include?(Hash)
    end

    def result
      [value.first, values]
    end

    def values
      value.last.map do |val|
        calling_mapper.for([value.first, val]).result
      end
    end
  end

  class NestedResourceValue < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)
    def self.handles?(value)
      value.is_a?(Array) && value.last.is_a?(Hash)
    end

    def result
      new_model = NestedResource.new
      new_attributes = ActiveFedoraAttributes.new(value.last)
      new_model.attributes = new_attributes.result
      new_model
    end
  end

  class NestedValkyrieResourceValue < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)
    def self.handles?(value)
      value.is_a?(::Valkyrie::Resource)
    end

    def result
      new_model = NestedResource.new
      new_attributes = ActiveFedoraAttributes.new(value.attributes)
      new_model.attributes = new_attributes.result
      new_model
    end
  end

  ConverterValueMapper.register(ResourceMapper)
end
