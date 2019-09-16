# frozen_string_literal: true

module Wings
  ##
  # A base value mapper for converting property values in the
  # `Valkyrie` type system to `ActiveFedora`/`ActiveTriples` type
  #
  # This top level matcher has registered several internal mappers which handle
  # indivdual value types from the source data.
  class ConverterValueMapper < ::Valkyrie::ValueMapper; end

  class PermissionValue < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)

    def self.handles?(value)
      value.first == :permissions
    end

    def result
      [value.first, permissions]
    end

    private

      def permissions
        value.last.map do |permission_attrs|
          if permission_attrs[:agent].starts_with? Hyrax::Group.name_prefix
            type = 'group'
            name = permission_attrs[:agent].dup
            name.slice!(Hyrax::Group.name_prefix)
          else
            type = 'person'
            name = permission_attrs[:agent].dup
          end

          hsh = { type: type, access: permission_attrs[:mode].to_s, name: name }
          hsh[:id] = permission_attrs[:id] if permission_attrs[:id]
          Hydra::AccessControls::Permission.new(hsh)
        end
      end
  end

  class NestedEmbargoValue < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)

    def self.handles?(value)
      value.first == :embargo
    end

    def result
      embargo = ActiveFedoraConverter.new(resource: Hyrax::Embargo.new(**value.last)).convert

      [:embargo, embargo]
    end
  end

  class IdValueMapper < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)

    def self.handles?(value)
      value.last.is_a? ::Valkyrie::ID
    end

    def result
      [value.first, values]
    end

    def values
      value.last.id
    end
  end

  class NestedLeaseValue < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)

    def self.handles?(value)
      value.first == :lease
    end

    def result
      lease = ActiveFedoraConverter.new(resource: Hyrax::Lease.new(**value.last)).convert

      [:lease, lease]
    end
  end

  class NestedResourceArrayValue < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)
    def self.handles?(value)
      value.last.is_a?(Array) && value.last.any? { |x| x.is_a? Dry::Struct }
    end

    def result
      ["#{value.first}_attributes".to_sym, values]
    end

    def values
      value.last.map do |val|
        calling_mapper.for([value.first, val]).result
      end.flat_map(&:last)
    end
  end

  class ArrayValue < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)

    def self.handles?(value)
      value.last.is_a?(Array)
    end

    def result
      [value.first, values]
    end

    def values
      value.last.map do |val|
        calling_mapper.for([value.first, val]).result
      end.flat_map(&:last)
    end
  end

  class NestedResourceValue < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)
    def self.handles?(value)
      value.last.is_a?(Dry::Struct)
    end

    def result
      attrs = ActiveFedoraAttributes.new(value.last.attributes).result
      attrs.delete(:read_groups)
      attrs.delete(:read_users)
      attrs.delete(:edit_groups)
      attrs.delete(:edit_users)

      [value.first, attrs]
    end
  end

  class ActiveFedoraAttributes
    attr_reader :attributes
    def initialize(attributes)
      @attributes = attributes
    end

    def result
      Hash[
        filter_attributes.map do |value|
          ConverterValueMapper.for(value).result
        end.select(&:present?)
      ]
    end

    ##
    # @return [Hash<Symbol, Object>]
    def filter_attributes
      # avoid reflections for now; `*_ids` can't be passed as attributes.
      # handling for reflections needs to happen in future work
      attrs = attributes.reject { |k, _| k.to_s.end_with? '_ids' }

      attrs.delete(:internal_resource)
      attrs.delete(:access_to)
      attrs.delete(:new_record)
      attrs.delete(:id)
      attrs.delete(:alternate_ids)
      attrs.delete(:created_at)
      attrs.delete(:updated_at)
      attrs.delete(:member_ids)

      # remove reflection id attributes and reinsert as strings
      attrs.select { |k| k.to_s.end_with? '_id' }.each_key do |k|
        val = attrs.delete(k)
        attrs[k] = val.to_s unless val.blank?
      end
      attrs.compact
    end
  end
end
