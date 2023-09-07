# frozen_string_literal: true

require 'wings/transformer_value_mapper'

module Wings
  ##
  # Transform AF attributes to Valkyrie::Resource attributes representation.
  class AttributeTransformer
    def self.for(obj)
      case obj
      when Hydra::PCDM::File
        FileAttributeTransformer.new
      else
        self
      end
    end

    def self.run(obj) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      attrs = obj.reflections.each_with_object({}) do |(key, reflection), mem| # rubocop:disable Metrics/BlockLength
        case reflection
        when ActiveFedora::Reflection::BelongsToReflection, # uses foreign_key SingularRDFPropertyReflection
             ActiveFedora::Reflection::BasicContainsReflection, # ???
             ActiveFedora::Reflection::FilterReflection, # rely on :extending_from
             ActiveFedora::Reflection::HasAndBelongsToManyReflection, # uses foreign_key RDFPropertyReflection
             ActiveFedora::Reflection::HasManyReflection, # captured by inverse relation
             ActiveFedora::Reflection::HasSubresourceReflection, # ???
          :noop
        when ActiveFedora::Reflection::OrdersReflection
          mem[:"#{reflection.options[:unordered_reflection].name.to_s.singularize}_ids"] ||= []
          mem[:"#{reflection.options[:unordered_reflection].name.to_s.singularize}_ids"] +=
            obj.association(reflection.name).target_ids_reader
        when ActiveFedora::Reflection::DirectlyContainsOneReflection
          mem[:"#{key.to_s.singularize}_id"] =
            obj.public_send(reflection.name)&.id
        when ActiveFedora::Reflection::IndirectlyContainsReflection
          mem[:"#{key.to_s.singularize}_ids"] ||= []
          mem[:"#{key.to_s.singularize}_ids"] +=
            obj.association(key).ids_reader
        when ActiveFedora::Reflection::DirectlyContainsReflection
          mem[:"#{key.to_s.singularize}_ids"] ||= []
          mem[:"#{key.to_s.singularize}_ids"] +=
            Array(obj.public_send(reflection.name)).map(&:id)
        when ActiveFedora::Reflection::RDFPropertyReflection
          mem[reflection.name.to_sym] =
            obj.public_send(reflection.name.to_sym)
        else
          raise NotImplementedError, "Expected a known ActiveFedora::Reflection, but got #{reflection}"
        end
      end

      obj.class.delegated_attributes.keys.each_with_object(attrs) do |attr_name, mem|
        next unless obj.respond_to?(attr_name) && !mem.key?(attr_name.to_sym)
        mem[attr_name.to_sym] = TransformerValueMapper.for(obj.public_send(attr_name)).result
      end
    end
  end

  class FileAttributeTransformer
    def run(obj)
      keys = obj.metadata_node.class.fields

      attributes = keys.each_with_object({}) do |attr_name, mem|
        next unless obj.respond_to?(attr_name) && !mem.key?(attr_name.to_sym)
        mem[attr_name.to_sym] = TransformerValueMapper.for(obj.public_send(attr_name)).result
      end

      attributes[:original_filename] = obj.original_name

      if obj.id.present?
        uri = Hyrax.config.translate_id_to_uri.call(obj.id)
        attributes[:file_identifier] = Wings::Valkyrie::Storage.cast_to_valkyrie_id(uri)
      end
      attributes[:type] = obj.metadata_node.type.to_a
      attributes[:size] = obj.size
      attributes
    end
  end
end
