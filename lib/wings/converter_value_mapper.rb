# frozen_string_literal: true

module Wings
  ##
  # A base value mapper for converting property values in the
  # `Valkyrie` type system to `ActiveFedora`/`ActiveTriples` type
  #
  # This top level matcher has registered several internal mappers which handle
  # indivdual value types from the source data.
  class ConverterValueMapper < ::Valkyrie::ValueMapper; end

  class ReservedAttributeValue < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)

    ATTRIBUTES = [:internal_resource, :access_to, :new_record, :id,
                  :alternate_ids, :created_at, :updated_at,
                  :optimistic_lock_token].freeze

    def self.handles?(value)
      ATTRIBUTES.include?(value.first)
    end

    def result
      nil
    end
  end

  class FedoraProtectedAttributes < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)

    ATTRIBUTES = [:create_date, :modified_date, :head, :tail, :has_model].freeze

    def self.handles?(value)
      ATTRIBUTES.include?(value.first)
    end

    def result
      nil
    end
  end

  class NilAttributeValue < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)

    def self.handles?(value)
      value.last.nil?
    end

    def result
      value
    end
  end

  class ReflectionIdValue < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)

    def self.handles?(value)
      value.first.to_s.end_with?('_id')
    end

    def result
      return nil if value.last.blank?

      [value.first, value.last.to_s]
    end
  end

  class MemberOfCollectionIds < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)

    def self.handles?(value)
      value.first == :member_of_collection_ids
    end

    def result
      collections = value.last.map { |id| ActiveFedora::Base.find(id.to_s) }
      [:member_of_collections, collections]
    end
  end

  class MemberIds < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)

    def self.handles?(value)
      value.first == :member_ids
    end

    def result
      members = value.last.map { |id| ActiveFedora::Base.find(id.to_s) }
      [:members, members]
    end
  end

  class FileIds < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)

    def self.handles?(value)
      value.first == :file_ids
    end

    def result
      files = value.last.map { |id| Hydra::PCDM::File.new(id.id) }
      [:files, files]
    end
  end

  ##
  # @todo ensure reflections round trip correctly, even though we avoid handling ids
  class ReflectionIdsValue < ::Valkyrie::ValueMapper
    ConverterValueMapper.register(self)

    def self.handles?(value)
      value.first.to_s.end_with?('_ids')
    end

    def result
      nil
    end
  end

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
      attrs = ActiveFedoraConverter.new(resource: value.last).attributes

      [value.first, ActiveFedoraAttributes.new(attrs).result]
    end
  end

  class ActiveFedoraAttributes
    attr_reader :attributes

    def initialize(attributes)
      attributes = attributes.merge(file_name: attributes[:original_filename]) if attributes[:original_filename]
      @attributes = attributes
    end

    def self.mapped_attributes(attributes:)
      new(attributes).result
    end

    def result
      Hash[
        attributes.map do |value|
          ConverterValueMapper.for(value).result
        end.select(&:present?)
      ]
    end
  end
end
