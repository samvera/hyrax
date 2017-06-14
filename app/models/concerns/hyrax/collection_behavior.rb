module Hyrax
  module CollectionBehavior
    extend ActiveSupport::Concern
    include Hydra::AccessControls::WithAccessRight
    include Hydra::WithDepositor # for access to apply_depositor_metadata
    include Hydra::AccessControls::Permissions
    include Hyrax::RequiredMetadata
    include Hydra::Works::CollectionBehavior
    include Hyrax::Noid
    include Hyrax::HumanReadableType
    include Hyrax::HasRepresentative
    include Hyrax::Permissions

    included do
      validates_with HasOneTitleValidator
      self.indexer = Hyrax::CollectionIndexer
    end

    # Add members using the members association.
    def add_members(new_member_ids)
      return if new_member_ids.nil? || new_member_ids.empty?
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

    private

      # Use this query to get the ids of the member objects (since the containment
      # association has been flipped)
      def member_object_ids
        return [] unless id
        ActiveFedora::Base.search_with_conditions("member_of_collection_ids_ssim:#{id}").map(&:id)
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
