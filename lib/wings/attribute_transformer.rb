# frozen_string_literal: true

require 'wings/transformer_value_mapper'

module Wings
  ##
  # Transform AF attributes to Valkyrie::Resource attributes representation.
  #
  class AttributeTransformer
    def self.run(obj, keys)
      # TODO: There is an open question about whether we want to treat all these relationships the same.  See Issue #3904.
      attrs = keys.select { |k| k.to_s.end_with? '_ids' }.each_with_object({}) do |attr_name, mem|
        mem[attr_name.to_sym] =
          TransformerValueMapper.for(obj.try(attr_name)).result ||
          TransformerValueMapper.for(attribute_ids_for(name: attr_name.chomp('_ids'), obj: obj)).result ||
          TransformerValueMapper.for(attribute_ids_for(name: attr_name.chomp('_ids').pluralize, obj: obj)).result || []
      end
      keys.each_with_object(attrs) do |attr_name, mem|
        next unless obj.respond_to?(attr_name) && !mem.key?(attr_name.to_sym)
        mem[attr_name.to_sym] = TransformerValueMapper.for(obj.public_send(attr_name)).result
      end
    end

    def self.attribute_ids_for(name:, obj:)
      attribute_value = obj.try(name)
      return if attribute_value.nil?
      Array(attribute_value).map(&:id)
    end
  end
end
