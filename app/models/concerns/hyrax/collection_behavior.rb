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

    included do
      validates_with HasOneTitleValidator
      self.indexer = Hyrax::CollectionIndexer

      property :collection_type_gid, predicate: ::RDF::Vocab::SCHEMA.additionalType, multiple: false do |index|
        index.as :symbol
      end

      after_find { |col| load_collection_type_instance(col) }
      # before_update { |col| validate_collection_type_gid(col) } # TODO: check that gid is not nil AND check that gid has not changed since it was read in (It is ok to go from nil to a value.)
    end

    delegate :nestable?, :discoverable?, :sharable?, :allow_multiple_membership?, :require_membership?, :assigns_workflow?, :assigns_visibility?, to: :collection_type

    # Get (and set) the collection_type when accessed
    def collection_type
      return @collection_type if @collection_type
      return nil if collection_type_gid.nil?
      collection_type = Hyrax::CollectionType.find_by_gid(collection_type_gid)
      raise StandardError, "Couldn't find Hyrax::CollectionType matching GID '#{collection_type_gid}'" if collection_type.nil?
      @collection_type = collection_type
    end

    # Add members using the members association.
    def add_members(new_member_ids)
      return if new_member_ids.blank?
      members << ActiveFedora::Base.find(new_member_ids)
    end

    # Add member objects by adding this collection to the objects' member_of_collection association.
    def add_member_objects(new_member_ids)
      Array(new_member_ids).each do |member_id|
        member = ActiveFedora::Base.find(member_id)
        member.member_of_collections << self
        member.save!
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

    protected

      def collection_type=(collection_type)
        @collection_type = collection_type
      end

    private

      # Load the collection_type attribute with an instance of the collection type of this collection based on the gid stored in the
      # collection object model.  Defaults to the default collection type (i.e. user_collection) so that all collections existing
      # before the addition of collection types do not need to be migrated.  They are assumed to be the default.
      # @param collection [Collection] an instance of the Collection model
      def load_collection_type_instance(collection)
        if collection.collection_type_gid.nil?
          collection.collection_type = Hyrax::CollectionType.find_or_create_default_collection_type
          collection.collection_type_gid = collection.collection_type.gid
          collection.save # do this one time on the first read by saving the gid in the collection object
        else
          collection.collection_type = Hyrax::CollectionType.find_by_gid(collection.collection_type_gid)
          # TODO: What to do if collection_type isn't valid?
          logger.warn("WARNING: Failed to load collection type instance.  Collection type is invalid.") unless collection_type_valid?(collection)
        end
      end

      # Validate that the collection has a valid instance of the collection type.
      # @param collection [Collection] an instance of the Collection model
      # @return true if valid; otherwise, false
      def collection_type_valid?(collection)
        return false if collection.collection_type.nil?
        return false unless collection.collection_type.is_a?(Hyrax::CollectionType)
        true
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
  end
end
