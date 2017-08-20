module Hyrax
  class CollectionType < ActiveRecord::Base
    self.table_name = 'hyrax_collection_types'
    validates :title, presence: true, uniqueness: true
    validates :machine_id, presence: true, uniqueness: true
    has_many :collection_type_participants, class_name: 'Hyrax::CollectionTypeParticipant', foreign_key: 'hyrax_collection_type_id', dependent: :destroy

    DEFAULT_ID = 'user_collection'.freeze
    DEFAULT_TITLE = 'User Collection'.freeze

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

    def gid
      URI::GID.build app: GlobalID.app, model_name: model_name.name.parameterize.to_sym, model_id: id unless id.nil?
    end

    def collections?
      # TODO: this is a stub method to check whether there are any collections with this
      # collection type.  We should think about best way to retrieve this information.
      # For testing, return 'true' to display the "Cannot delete" modal.
      # And return 'false' to display the delete confirmation modal.
      true
    end

    def self.find_or_create_default_collection_type
      return find_by(machine_id: DEFAULT_ID) if exists?(machine_id: DEFAULT_ID)
      create_default_collection_type(machine_id: DEFAULT_ID, title: DEFAULT_TITLE)
    end

    def self.create_default_collection_type(machine_id:, title:)
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
  end
end
