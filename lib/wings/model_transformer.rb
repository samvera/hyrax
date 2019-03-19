# frozen_string_literal: true

require 'wings/transformer_value_mapper'
require 'wings/models/concerns/collection_behavior'
require 'wings/hydra/works/models/concerns/work_valkyrie_behavior'
require 'wings/hydra/works/models/concerns/file_set_valkyrie_behavior'
require 'wings/services/file_converter_service'

module Wings
  ##
  # Transforms ActiveFedora models or objects into Valkyrie::Resource models or
  # objects
  #
  # @see https://github.com/samvera-labs/valkyrie/blob/master/lib/valkyrie/resource.rb
  #
  # Similar to an orm_converter class in other valkyrie persisters. Also used by
  # the Valkyrizable mixin to make AF objects able to return their
  # Valkyrie::Resource representation.
  #
  # @example getting a valkyrie resource
  #   work     = GenericWork.new(id: 'an_identifier')
  #   resource = Wings::ModelTransformer.for(work)
  #
  #   resource.alternate_ids # => [#<Valkyrie::ID:0x... id: 'an_identifier'>]
  #
  class ModelTransformer
    ##
    # @!attribute [rw] pcdm_object
    #   @return [ActiveFedora::Base]
    attr_accessor :pcdm_object

    ##
    # @param pcdm_object [ActiveFedora::Base]
    def initialize(pcdm_object:)
      self.pcdm_object = pcdm_object
    end

    ##
    # Factory
    #
    # @param pcdm_object [ActiveFedora::Base]
    #
    # @return [::Valkyrie::Resource] a resource mirroring `pcdm_object`
    def self.for(pcdm_object)
      new(pcdm_object: pcdm_object).build
    end

    ##
    # @param reflections [Hash<Symbol, Object>]
    #
    # @return [Array<Symbol>]
    def self.relationship_keys_for(reflections:)
      relationships = reflections
                      .keys
                      .reject { |k| k.to_s.include?('id') }
                      .map { |k| k.to_s.singularize + '_ids' }
      relationships.delete(:member_ids) # Remove here.  Members will be extracted as ordered_members in attributes method.
      relationships
    end

    ##
    # Builds a `Valkyrie::Resource` equivalent to the `pcdm_object`
    #
    # @return [::Valkyrie::Resource] a resource mirroring `pcdm_object`
    def build
      klass = ResourceClassCache.instance.fetch(pcdm_object) do
        self.class.to_valkyrie_resource_class(klass: pcdm_object.class)
      end
      pcdm_object.id = minted_id if pcdm_object.id.nil?
      attrs = attributes.tap { |hash| hash[:new_record] = pcdm_object.new_record? }
      resource = klass.new(alternate_ids: [::Valkyrie::ID.new(pcdm_object.id)], **attrs)
      build_files(resource)
      resource
    end

    ##
    # Caches dynamically generated `Valkyrie::Resource` subclasses mapped from
    # legacy `ActiveFedora` model classes.
    #
    # @example
    #   cache = ResourceClassCache.new
    #
    #   klass = cache.fetch(GenericWork) do
    #     # logic mapping GenericWork to a Valkyrie::Resource subclass
    #   end
    #
    class ResourceClassCache
      include Singleton

      ##
      # @!attribute [r] cache
      #   @return [Hash<Class, Class>]
      attr_reader :cache

      def initialize
        @cache = {}
      end

      ##
      # @param key [Class] the ActiveFedora class to map
      #
      # @return [Class]
      def fetch(key)
        @cache.fetch(key) do
          @cache[key] = yield
        end
      end
    end

    ##
    # @note The method signature is to conform to Valkyrie's method signature
    #   for ::Valkyrie.config.resource_class_resolver
    #
    # @param class_name [String] a string representation of an `ActiveFedora`
    #   model
    #
    # @return [Class] a dynamically generated `Valkyrie::Resource` subclass
    #   mirroring the provided class name
    #
    def self.convert_class_name_to_valkyrie_resource_class(class_name)
      klass = class_name.constantize
      to_valkyrie_resource_class(klass: klass)
    end

    ##
    # @param klass [String] an `ActiveFedora` model
    #
    # @return [Class] a dyamically generated `Valkyrie::Resource` subclass
    #   mirroring the provided `ActiveFedora` model
    #
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength because metaprogramming a class
    #   results in long methods
    def self.to_valkyrie_resource_class(klass:)
      relationship_keys = klass.respond_to?(:reflections) ? relationship_keys_for(reflections: klass.reflections) : []
      relationship_keys.delete('member_ids')
      relationship_keys.delete('member_of_collection_ids')

      Class.new(ActiveFedoraResource) do
        include Wings::CollectionBehavior if klass.included_modules.include?(Hyrax::CollectionBehavior)
        include Wings::Works::WorkValkyrieBehavior if klass.included_modules.include?(Hyrax::WorkBehavior)
        include Wings::Works::FileSetValkyrieBehavior if klass.included_modules.include?(Hyrax::FileSetBehavior)

        # Based on Valkyrie implementation, we call Class.to_s to define
        # the internal resource.
        @internal_resource = klass.to_s

        class << self
          attr_reader :internal_resource
        end

        def self.to_s
          internal_resource
        end

        klass.properties.each_key do |property_name|
          attribute property_name.to_sym, ::Valkyrie::Types::String
        end

        relationship_keys.each do |linked_property_name|
          attribute linked_property_name.to_sym, ::Valkyrie::Types::Set.of(::Valkyrie::Types::ID)
        end

        # Defined after properties in case we have an `internal_resource` property.
        # This may not be ideal, but based on my understanding of the `internal_resource`
        # usage in Valkyrie, I'd rather keep synchronized the instance_method and class_method value for
        # `internal_resource`
        def internal_resource
          self.class.internal_resource
        end
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    class ActiveFedoraResource < ::Valkyrie::Resource
      attribute :alternate_ids, ::Valkyrie::Types::Array
      attribute :embargo_id,    ::Valkyrie::Types::ID
      attribute :lease_id,      ::Valkyrie::Types::ID
      attribute :visibility,    ::Valkyrie::Types::Symbol
    end

    class AttributeTransformer
      def self.run(obj, keys)
        keys.each_with_object({}) do |attr_name, mem|
          next unless obj.respond_to? attr_name
          mem[attr_name.to_sym] = TransformerValueMapper.for(obj.public_send(attr_name)).result
        end
      end
    end

    private

      def minted_id
        ::Noid::Rails.config.minter_class.new.mint
      end

      def attributes
        all_keys =
          pcdm_object.attributes.keys +
          self.class.relationship_keys_for(reflections: pcdm_object.reflections)
        AttributeTransformer.run(pcdm_object, all_keys)
                            .merge(created_at: pcdm_object.try(:create_date),
                                   updated_at: pcdm_object.try(:modified_date),
                                   embargo_id: pcdm_object.try(:embargo)&.id,
                                   lease_id:   pcdm_object.try(:lease)&.id,
                                   visibility: pcdm_object.try(:visibility),
                                   member_ids: pcdm_object.try(:ordered_member_ids)) # We want members in order, so extract from ordered_members.
      end

      ##
      # Builds a `Valkyrie::Resource` equivalent for any files attached to the `pcdm_object`
      #
      # @return [Array<::Valkyrie::Resource>] resources mirroring files attached to `pcdm_object`
      def build_files(resource)
        return unless pcdm_object.respond_to?(:files) && pcdm_object.files.present?
        return unless resource.respond_to? :file_metadata
        pcdm_object.files.each do |fil|
          Wings::FileConverterService.convert_and_add_file_to_resource(fil, resource)
        end
      end
  end
  # rubocop:enable Style/ClassVars
end
