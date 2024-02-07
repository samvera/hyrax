# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
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
    # Builds a `Valkyrie::Resource` equivalent to the `pcdm_object`
    #
    # @return [::Valkyrie::Resource] a resource mirroring `pcdm_object`
    # rubocop:disable Metrics/AbcSize
    def build
      klass = cache.fetch(pcdm_object.class) do
        OrmConverter.to_valkyrie_resource_class(klass: pcdm_object.class)
      end

      mint_id unless pcdm_object.id

      attrs = attributes.tap { |hash| hash[:new_record] = pcdm_object.new_record? }
      attrs[:alternate_ids] = [::Valkyrie::ID.new(pcdm_object.id)] if pcdm_object.id

      klass.new(**attrs).tap do |resource|
        resource.lease = pcdm_object.lease&.valkyrie_resource if pcdm_object.respond_to?(:lease) && pcdm_object.lease
        resource.embargo = pcdm_object.embargo&.valkyrie_resource if pcdm_object.respond_to?(:embargo) && pcdm_object.embargo
        check_size(resource)
        check_pcdm_use(resource)
        ensure_current_permissions(resource)
      end
    end

    def check_size(resource)
      return unless resource.respond_to?(:recorded_size) && pcdm_object.respond_to?(:size)
      resource.recorded_size = [pcdm_object.size.to_i]
    end

    def check_pcdm_use(resource)
      return unless resource.respond_to?(:pcdm_use) &&
                    pcdm_object.respond_to?(:metadata_node) &&
                    pcdm_object&.metadata_node&.respond_to?(:type)
      resource.pcdm_use = pcdm_object.metadata_node.type.to_a
    end

    def ensure_current_permissions(resource)
      return if pcdm_object.try(:access_control).blank?

      # set permissions on the locally cached permission manager if one is present,
      # otherwise, we can just rely on the `access_control_ids`.
      return unless resource.respond_to?(:permission_manager)

      # When the pcdm_object has an access_control (see above) but there's no access_control_id, we
      # need to rely on the computed access_control object.  Why?  There are tests that fail.
      acl = if pcdm_object.access_control_id.nil?
              pcdm_object.access_control.valkyrie_resource
            else
              begin
                # Given that we have an access_control AND an access_control_id, we want to ensure
                # that we fetch the access_control from persistence.  Why?  Because when we update
                # an ACL and are using those adapters, we will write the ACL to the Valkyrie adapter
                # without writing the work to the Valkyrie adapter.  This might be a failing, but
                # migrations in place are hard.
                acl_id = pcdm_object.access_control_id
                acl_id = ::Valkyrie::ID.new(acl_id) unless acl_id.is_a?(::Valkyrie::ID)
                Hyrax.query_service.find_by(id: acl_id)
              rescue ::Valkyrie::Persistence::ObjectNotFoundError
                pcdm_object.access_control.valkyrie_resource
              end
            end
      resource.permission_manager.acl.permissions = acl.permissions
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
      id = pcdm_object.try(:assign_id)

      pcdm_object.id = id if id.present?
    end

    def attributes
      transformer = AttributeTransformer.for(pcdm_object)
      result = transformer.run(pcdm_object).merge(additional_attributes)

      append_embargo(result)
      append_lease(result)
      append_permissions(result)

      result
    end

    def additional_attributes
      { :id => pcdm_object.id,
        :created_at => pcdm_object.try(:create_date),
        :updated_at => pcdm_object.try(:modified_date),
        ::Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK => lock_token }
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
      embargo_attrs[:id] = ::Valkyrie::ID.new(embargo_attrs[:id]) if embargo_attrs[:id]

      attrs[:embargo] = Hyrax::Embargo.new(**embargo_attrs)
    end

    def append_lease(attrs)
      return unless pcdm_object.try(:lease)
      lease_attrs = pcdm_object.lease.attributes.symbolize_keys
      lease_attrs[:id] = ::Valkyrie::ID.new(lease_attrs[:id]) if lease_attrs[:id]

      attrs[:lease] = Hyrax::Lease.new(**lease_attrs)
    end

    def append_permissions(attrs)
      return unless pcdm_object.try(:permissions)
      attrs[:permissions] = pcdm_object.permissions.map do |permission|
        agent = permission.type == 'group' ? "group/#{permission.agent_name}" : permission.agent_name

        Hyrax::Permission.new(id: permission.id,
                              mode: permission.access.to_sym,
                              agent: agent,
                              access_to: ::Valkyrie::ID.new(permission.access_to_id),
                              new_record: permission.new_record?)
      end

      attrs[:access_to] = attrs[:permissions].find { |p| p.access_to&.id&.present? }&.access_to
    end
  end
end
# rubocop:enable Metrics/ClassLength
