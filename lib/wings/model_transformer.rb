# frozen_string_literal: true

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
    # @return [::Valkyrie::Resource] a resource mirroiring `pcdm_object`
    def self.for(pcdm_object)
      new(pcdm_object: pcdm_object).build
    end

    ##
    # Builds a `Valkyrie::Resource` equivalent to the `pcdm_object`
    #
    # @return [::Valkyrie::Resource] a resource mirroring `pcdm_object`
    def build
      klass = cache.fetch(pcdm_object) do
        OrmConverter.to_valkyrie_resource_class(klass: pcdm_object.class)
      end

      mint_id unless pcdm_object.id

      attrs = attributes.tap { |hash| hash[:new_record] = pcdm_object.new_record? }
      attrs[:alternate_ids] = [::Valkyrie::ID.new(pcdm_object.id)] if pcdm_object.id

      klass.new(**attrs).tap { |resource| ensure_current_permissions(resource) }
    end

    def ensure_current_permissions(resource)
      return if pcdm_object.try(:access_control).blank?

      # set permissions on the locally cached permission manager if one is present,
      # otherwise, we can just rely on the `access_control_ids`.
      return unless resource.respond_to?(:permission_manager)

      resource.permission_manager.acl.permissions =
        pcdm_object.access_control.valkyrie_resource.permissions
    end

    ##
    # @return [ResourceClassCache]
    def cache
      ResourceClassCache.instance
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

    private

    def mint_id
      id = pcdm_object.assign_id

      pcdm_object.id = id if id.present?
    end

    def attributes
      attribute_source = pcdm_object.try(:metadata_node) || pcdm_object

      all_keys =
        attribute_source.attributes.keys +
        OrmConverter.relationship_keys_for(reflections: pcdm_object.try(:reflections))

      result = AttributeTransformer.for(pcdm_object)
                                   .run(pcdm_object, all_keys)
                                   .merge(reflection_ids)
                                   .merge(additional_attributes)

      append_embargo(result)
      append_lease(result)

      result
    end

    def reflection_ids
      keys = pcdm_object.try(:reflections)&.keys || []

      keys.select { |k| k.to_s.end_with? '_id' }.each_with_object({}) do |k, mem|
        mem[k] = pcdm_object.try(k)
      end
    end

    def additional_attributes
      { :created_at => pcdm_object.try(:create_date),
        :updated_at => pcdm_object.try(:modified_date),
        :member_ids => member_ids,
        ::Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK => lock_token }
    end

    # Prefer ordered members, but if ordered members don't exist, use non-ordered members.
    def member_ids
      ordered_member_ids = pcdm_object.try(:ordered_member_ids)
      return ordered_member_ids if ordered_member_ids.present?
      pcdm_object.try(:member_ids)
    end

    def lock_token
      result = []
      result << ::Valkyrie::Persistence::OptimisticLockToken.new(adapter_id: 'wings-fedora-etag', token: pcdm_object.etag) unless pcdm_object.new_record?

      graph_node = pcdm_object.try(:resource) || pcdm_object.metadata_node
      last_modified_literal = graph_node.first_object([nil, RDF::URI("http://fedora.info/definitions/v4/repository#lastModified"), nil])
      token = last_modified_literal&.object&.to_s
      result << ::Valkyrie::Persistence::OptimisticLockToken.new(adapter_id: 'wings-fedora-last-modified', token: token) if token
      result
    end

    def append_embargo(attrs)
      return unless pcdm_object.try(:embargo)
      embargo_attrs = pcdm_object.embargo.attributes.symbolize_keys
      embargo_attrs[:embargo_history] = embargo_attrs[:embargo_history].to_a
      embargo_attrs[:id] = ::Valkyrie::ID.new(embargo_attrs[:id]) if embargo_attrs[:id]

      attrs[:embargo] = Hyrax::Embargo.new(**embargo_attrs)
    end

    def append_lease(attrs)
      return unless pcdm_object.try(:lease)
      lease_attrs = pcdm_object.lease.attributes.symbolize_keys
      lease_attrs[:lease_history] = lease_attrs[:embargo_history].to_a
      lease_attrs[:id] = ::Valkyrie::ID.new(lease_attrs[:id]) if lease_attrs[:id]

      attrs[:lease] = Hyrax::Lease.new(**lease_attrs)
    end
  end
end
