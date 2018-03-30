module Hyrax
  module CollectionBehavior
    extend ActiveSupport::Concern
    include Hydra::AccessControls::WithAccessRight
    include Hydra::WithDepositor # for access to apply_depositor_metadata
    include Hydra::AccessControls::Permissions
    include Hyrax::CoreMetadata
    include Hydra::Works::CollectionBehavior
    include Hyrax::Noid
    include Hyrax::HumanReadableType
    include Hyrax::HasRepresentative
    include Hyrax::Permissions
    include Hyrax::CollectionNesting

    included do
      validates_with HasOneTitleValidator
      after_destroy :destroy_permission_template

      self.indexer = Hyrax::CollectionIndexer

      class_attribute :index_collection_type_gid_as, writer: false
      self.index_collection_type_gid_as = [:symbol]

      property :collection_type_gid, predicate: ::RDF::Vocab::SCHEMA.additionalType, multiple: false do |index|
        index.as(*index_collection_type_gid_as)
      end

      # validates that collection_type_gid is present
      validates :collection_type_gid, presence: true

      # Need to define here in order to override setter defined by ActiveTriples
      def collection_type_gid=(new_collection_type_gid)
        raise "Can't modify collection type of this collection" if persisted? && !collection_type_gid_was.nil? && collection_type_gid_was != new_collection_type_gid
        new_collection_type = Hyrax::CollectionType.find_by_gid!(new_collection_type_gid)
        super
        @collection_type = new_collection_type
        collection_type_gid
      end
    end

    delegate(*Hyrax::CollectionType.collection_type_settings_methods, to: :collection_type)

    # Get the collection_type when accessed
    def collection_type
      @collection_type ||= Hyrax::CollectionType.find_by_gid!(collection_type_gid)
    end

    def collection_type=(new_collection_type)
      self.collection_type_gid = new_collection_type.gid
    end

    # Add members using the members association.
    def add_members(new_member_ids)
      return if new_member_ids.blank?
      members << ActiveFedora::Base.find(new_member_ids)
    end

    # Add member objects by adding this collection to the objects' member_of_collection association.
    def add_member_objects(new_member_ids)
      Array(new_member_ids).collect do |member_id|
        member = ActiveFedora::Base.find(member_id)
        message = Hyrax::MultipleMembershipChecker.new(item: member).check(collection_ids: id, include_current_members: true)
        if message
          member.errors.add(:collections, message)
        else
          member.member_of_collections << self
          member.save!
        end
        member
      end
    end

    def member_objects
      ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id}")
    end

    def to_s
      title.present? ? title.join(' | ') : 'No Title'
    end

    module ClassMethods
      # This governs which partial to draw when you render this type of object
      def _to_partial_path #:nodoc:
        @_to_partial_path ||= begin
          element = ActiveSupport::Inflector.underscore(ActiveSupport::Inflector.demodulize(name))
          collection = ActiveSupport::Inflector.tableize(name)
          "hyrax/#{collection}/#{element}".freeze
        end
      end

      def collection_type_gid_document_field_name
        Solrizer.solr_name('collection_type_gid', *index_collection_type_gid_as)
      end
    end

    # Compute the sum of each file in the collection using Solr to
    # avoid having to access Fedora
    #
    # @return [Fixnum] size of collection in bytes
    # @raise [RuntimeError] unsaved record does not exist in solr
    def bytes
      return 0 if member_object_ids.empty?

      raise "Collection must be saved to query for bytes" if new_record?

      # One query per member_id because Solr is not a relational database
      member_object_ids.collect { |work_id| size_for_work(work_id) }.sum
    end

    # Use this query to get the ids of the member objects (since the containment
    # association has been flipped)
    def member_object_ids
      return [] unless id
      ActiveFedora::Base.search_with_conditions("member_of_collection_ids_ssim:#{id}").map(&:id)
    end

    # @api public
    # Retrieve the permission template for this collection.
    # @return [Hyrax::PermissionTemplate]
    # @raise [ActiveRecord::RecordNotFound]
    def permission_template
      Hyrax::PermissionTemplate.find_by!(source_id: id)
    end

    # Calculate and update who should have read/edit access to the collections based on who
    # has access in PermissionTemplateAccess
    def reset_access_controls!
      update!(edit_users: permission_template_edit_users,
              edit_groups: permission_template_edit_groups,
              read_users: permission_template_read_users,
              read_groups: (permission_template_read_groups + visibility_group).uniq)
    end

    private

      def permission_template_edit_users
        permission_template.agent_ids_for(access: 'manage', agent_type: 'user')
      end

      def permission_template_edit_groups
        permission_template.agent_ids_for(access: 'manage', agent_type: 'group')
      end

      def permission_template_read_users
        (permission_template.agent_ids_for(access: 'view', agent_type: 'user') +
          permission_template.agent_ids_for(access: 'deposit', agent_type: 'user')).uniq
      end

      def permission_template_read_groups
        (permission_template.agent_ids_for(access: 'view', agent_type: 'group') +
          permission_template.agent_ids_for(access: 'deposit', agent_type: 'group')).uniq -
          [::Ability.registered_group_name, ::Ability.public_group_name]
      end

      def visibility_group
        return [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC] if visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        return [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED] if visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        []
      end

      # Calculate the size of all the files in the work
      # @param work_id [String] identifer for a work
      # @return [Integer] the size in bytes
      def size_for_work(work_id)
        argz = { fl: "id, #{file_size_field}",
                 fq: "{!join from=#{member_ids_field} to=id}id:#{work_id}" }
        files = ::FileSet.search_with_conditions({}, argz)
        files.reduce(0) { |sum, f| sum + f[file_size_field].to_i }
      end

      # Field name to look up when locating the size of each file in Solr.
      # Override for your own installation if using something different
      def file_size_field
        Solrizer.solr_name(:file_size, Hyrax::FileSetIndexer::STORED_LONG)
      end

      # Solr field name works use to index member ids
      def member_ids_field
        Solrizer.solr_name('member_ids', :symbol)
      end

      def destroy_permission_template
        permission_template.destroy
      rescue ActiveRecord::RecordNotFound
        true
      end
  end
end
