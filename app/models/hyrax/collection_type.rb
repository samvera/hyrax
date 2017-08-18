module Hyrax
  class CollectionType < ActiveRecord::Base
    self.table_name = 'hyrax_collection_types'
    validates :title, presence: true, uniqueness: true
    validates :machine_id, presence: true, uniqueness: true
    before_save :ensure_no_collections
    before_destroy :ensure_no_collections

    DEFAULT_ID = 'user_collection'.freeze
    DEFAULT_TITLE = 'User Collection'.freeze

    def title=(value)
      super
      assign_machine_id
    end

    # These are provided as a convenience method based on prior design discussions.
    # The deprecations are added to allow upstream developers to continue with what
    # they had already been doing. These can be removed as part of merging
    # the collections-sprint branch into master (or before hand if coordinated)
    alias_attribute :discovery, :discoverable
    deprecation_deprecate discovery: "prefer #discoverable instead"
    alias_attribute :sharing, :sharable
    deprecation_deprecate sharing: "prefer #sharable instead"
    alias_attribute :multiple_membership, :allow_multiple_membership
    deprecation_deprecate multiple_membership: "prefer #allow_multiple_membership instead"
    alias_attribute :workflow, :assigns_workflow
    deprecation_deprecate workflow: "prefer #assigns_workflow instead"
    alias_attribute :visibility, :assigns_visibility
    deprecation_deprecate visibility: "prefer #assigns_visibility instead"

    # Find the collection type associated with the Global Identifier (gid)
    # @param [String] gid - Global Identifier for this collection_type (e.g. gid://internal/hyrax-collectiontype/3)
    # @return [Hyrax::CollectionType] if record matching gid is found, an instance of Hyrax::CollectionType with id = the model_id portion of the gid (e.g. 3)
    # @return [False] if record matching gid is not found
    def self.find_by_gid(gid)
      find(GlobalID.new(gid).model_id)
    rescue ActiveRecord::RecordNotFound
      false
    end

    # Find the collection type associated with the Global Identifier (gid)
    # @param [String] gid - Global Identifier for this collection_type (e.g. gid://internal/hyrax-collectiontype/3)
    # @return [Hyrax::CollectionType] an instance of Hyrax::CollectionType with id = the model_id portion of the gid (e.g. 3)
    # @raise [ActiveRecord::RecordNotFound] if record matching gid is not found
    def self.find_by_gid!(gid)
      find(GlobalID.new(gid).model_id)
    rescue ActiveRecord::RecordNotFound
      raise ActiveRecord::RecordNotFound, "Couldn't find Hyrax::CollectionType matching GID '#{gid}'"
    end

    # Return the Global Identifier for this collection type.
    # @return [String] Global Identifier (gid) for this collection_type (e.g. gid://internal/hyrax-collectiontype/3)
    def gid
      return nil if id.nil?
      # TODO: From a modeling perspective, I'm not sure which of these we should make the <object_value>.  For now, we will store in Fedora object as string, but might want to revisit.
      # rdf_uri = RDF::URI.new(uri_gid) # TODO: Decide if this should return RDF::URI - ActiveTriples converts this to an ActiveTriples relationship that is a new triple with <subject> = gid uri
      uri_gid = URI::GID.build(app: GlobalID.app, model_name: model_name.name.parameterize.to_sym, model_id: id) unless id.nil? # ActiveTriples won't accept this as an <object_value>
      uri_gid.to_s # ActiveTriples treats this string version as a literal <object_value>
    end

    def collections
      return [] unless gid
      ActiveFedora::Base.where(collection_type_gid_ssim: gid.to_s)
    end

    def collections?
      collections.count > 0
    end

    def self.find_or_create_default_collection_type
      find_by(machine_id: DEFAULT_ID) || create_default_collection_type
    end

    def self.create_default_collection_type(machine_id: DEFAULT_ID, title: DEFAULT_TITLE)
      create(machine_id: machine_id, title: title) do |c|
        c.description = 'A User Collection can be created by any user to organize their works.'
        c.nestable = false
        c.discoverable = true
        c.sharable = true
        c.allow_multiple_membership = true
        c.require_membership = false
        c.assigns_workflow = false
        c.assigns_visibility = false
      end
    end

    private

      def assign_machine_id
        # FIXME: This method allows for the possibility of collisions
        self.machine_id ||= title.parameterize.underscore.to_sym if title.present?
      end

      def ensure_no_collections
        return true unless collections?
        errors[:base] << I18n.t('hyrax.admin.collection_types.error_not_empty')
        throw :abort
      end
  end
end
