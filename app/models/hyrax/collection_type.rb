# frozen_string_literal: true
module Hyrax
  class CollectionType < ActiveRecord::Base
    # @!method id
    #   @return [Integer]
    # @!method description
    #   @return [String]
    # @!method machine_id
    #   @return [String]
    # @!method title
    #   @return [String]
    self.table_name = 'hyrax_collection_types'
    validates :title, presence: true, uniqueness: true
    validates :machine_id, presence: true, uniqueness: true
    before_save :ensure_no_settings_changes_for_admin_set_type
    before_save :ensure_no_settings_changes_for_user_collection_type
    before_save :ensure_no_settings_changes_if_collections_exist
    before_destroy :ensure_no_collections
    has_many :collection_type_participants, class_name: 'Hyrax::CollectionTypeParticipant', foreign_key: 'hyrax_collection_type_id', dependent: :destroy

    USER_COLLECTION_MACHINE_ID    = 'user_collection'
    USER_COLLECTION_DEFAULT_TITLE = I18n.t('hyrax.collection_type.default_title', default: 'User Collection').freeze

    ADMIN_SET_MACHINE_ID = 'admin_set'
    ADMIN_SET_DEFAULT_TITLE = I18n.t('hyrax.collection_type.admin_set_title', default: 'Admin Set').freeze

    ##
    # @note mints a #machine_id (?!)
    # @return [void]
    def title=(value)
      super
      assign_machine_id
    end

    class_attribute :collection_type_settings_methods, instance_writer: false
    self.collection_type_settings_methods = [:nestable?, :discoverable?, :brandable?, :sharable?, :share_applies_to_new_works?,
                                             :allow_multiple_membership?, :require_membership?, :assigns_workflow?,
                                             :assigns_visibility?]

    # These are provided as a convenience method based on prior design discussions.
    alias_attribute :discovery, :discoverable
    alias_attribute :sharing, :sharable
    alias_attribute :multiple_membership, :allow_multiple_membership
    alias_attribute :workflow, :assigns_workflow
    alias_attribute :visibility, :assigns_visibility
    alias_attribute :branding, :brandable

    # Find the collection type associated with the Global Identifier (gid)
    # @param [String] gid - Global Identifier for this collection_type (e.g. gid://internal/hyrax-collectiontype/3)
    # @return [Hyrax::CollectionType] if record matching gid is found, an instance of Hyrax::CollectionType with id = the model_id portion of the gid (e.g. 3)
    # @return [False] if record matching gid is not found
    def self.find_by_gid(gid)
      find(GlobalID.new(gid).model_id)
    rescue ActiveRecord::RecordNotFound, URI::InvalidURIError
      false
    end

    # Return an array of global identifiers for collection types that do not allow multiple membership.
    # @return [Array<String>] an array of Global Identifiers
    # @see #gid
    # @see Hyrax::MultipleMembershipChecker
    def self.gids_that_do_not_allow_multiple_membership
      where(allow_multiple_membership: false).map(&:gid)
    end

    # Find the collection type associated with the Global Identifier (gid)
    # @param [String] gid - Global Identifier for this collection_type (e.g. gid://internal/hyrax-collectiontype/3)
    # @return [Hyrax::CollectionType] an instance of Hyrax::CollectionType with id = the model_id portion of the gid (e.g. 3)
    # @raise [ActiveRecord::RecordNotFound] if record matching gid is not found
    def self.find_by_gid!(gid)
      find_by_gid(gid) ||
        raise(ActiveRecord::RecordNotFound, "Couldn't find Hyrax::CollectionType matching GID '#{gid}'")
    end

    # Return the Global Identifier for this collection type.
    # @return [String] Global Identifier (gid) for this collection_type (e.g. gid://internal/hyrax-collectiontype/3)
    def gid
      URI::GID.build(app: GlobalID.app, model_name: model_name.name.parameterize.to_sym, model_id: id).to_s if id
    end

    ##
    # @return [Enumerable<Collection, PcdmCollection>]
    def collections(use_valkyrie: false)
      return [] unless id
      return Hyrax.custom_queries.find_collections_by_type(global_id: gid) if use_valkyrie
      ActiveFedora::Base.where(collection_type_gid_ssim: gid.to_s)
    end

    ##
    # @deprecated Use #collections.any? instead
    #
    # @return [Boolean] True if there is at least one collection of this type
    def collections?
      Deprecation.warn('Use #collections.any? instead.') && collections.any?
    end

    # @return [Boolean] True if this is the Admin Set type
    def admin_set?
      machine_id == ADMIN_SET_MACHINE_ID
    end

    # @return [Boolean] True if this is the User Collection type
    def user_collection?
      machine_id == USER_COLLECTION_MACHINE_ID
    end

    # @return [Boolean] True if there is at least one collection type that has nestable? true
    def self.any_nestable?
      where(nestable: true).any?
    end

    # Find or create the default type (i.e., user collection) as defined by:
    #
    # * USER_COLLECTION_MACHINE_ID
    # * USER_COLLECTION_DEFAULT_TITLE
    # * Hyrax::CollectionTypes::CreateService::USER_COLLECTION_OPTIONS
    #
    # @see Hyrax::CollectionTypes::CreateService
    #
    # @return [Hyrax::CollectionType] where machine_id = USER_COLLECTION_MACHINE_ID
    def self.find_or_create_default_collection_type
      find_by(machine_id: USER_COLLECTION_MACHINE_ID) || Hyrax::CollectionTypes::CreateService.create_user_collection_type
    end

    # Find or create the Admin Set collection type as defined by:
    #
    # * ADMIN_SET_MACHINE_ID
    # * ADMIN_SET_DEFAULT_TITLE
    # * Hyrax::CollectionTypes::CreateService::ADMIN_SET_OPTIONS
    #
    # @see Hyrax::CollectionTypes::CreateService
    #
    # @return [Hyrax::CollectionType] where machine_id = ADMIN_SET_MACHINE_ID
    def self.find_or_create_admin_set_type
      find_by(machine_id: ADMIN_SET_MACHINE_ID) || Hyrax::CollectionTypes::CreateService.create_admin_set_type
    end

    private

    def assign_machine_id
      # FIXME: This method allows for the possibility of collisions
      self.machine_id ||= title.parameterize.underscore.to_sym if title.present?
    end

    def ensure_no_collections
      return true unless collections.any?
      errors[:base] << I18n.t('hyrax.admin.collection_types.errors.not_empty')
      throw :abort
    end

    def ensure_no_settings_changes_for_admin_set_type
      return true unless admin_set? && collection_type_settings_changed? && exists_for_machine_id?(ADMIN_SET_MACHINE_ID)
      errors[:base] << I18n.t('hyrax.admin.collection_types.errors.no_settings_change_for_admin_sets')
      throw :abort
    end

    def ensure_no_settings_changes_for_user_collection_type
      return true unless user_collection? && collection_type_settings_changed? && exists_for_machine_id?(USER_COLLECTION_MACHINE_ID)
      errors[:base] << I18n.t('hyrax.admin.collection_types.errors.no_settings_change_for_user_collections')
      throw :abort
    end

    def ensure_no_settings_changes_if_collections_exist
      return true unless collections.any?
      return true unless collection_type_settings_changed?
      errors[:base] << I18n.t('hyrax.admin.collection_types.errors.no_settings_change_if_not_empty')
      throw :abort
    end

    def collection_type_settings_changed?
      (changes.keys & ['nestable', 'brandable', 'discoverable', 'sharable', 'share_applies_to_new_works', 'allow_multiple_membership', 'require_membership', 'assigns_workflow', 'assigns_visibility']).any?
    end

    def exists_for_machine_id?(machine_id)
      self.class.exists?(machine_id: machine_id)
    end
  end
end
