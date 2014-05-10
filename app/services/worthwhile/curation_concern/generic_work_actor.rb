module Worthwhile
  module CurationConcern
    module GenericWorkActor 
      extend ActiveSupport::Concern
      
      included do
        include Worthwhile::CurationConcern::BaseActor
      end
      
      def create
        assign_pid && super && attach_files && assign_representative
      end

      def update
        add_to_collections(attributes.delete(:collection_ids)) &&
          super && attach_files
      end

      delegate :visibility_changed?, to: :curation_concern

      protected

      def assign_pid
        curation_concern.inner_object.pid = CurationConcern.mint_a_pid
      end

      def files
        return @files if defined?(@files)
        @files = [attributes[:files]].flatten.compact
      end

      def attach_files
        files.all? do |file|
          attach_file(file)
        end
      end

      # The default behavior of active_fedora's has_and_belongs_to_many association,
      # when assigning the id accessor (e.g. collection_ids = ['foo:1']) is to add
      # to new collections, but not remove from old collections.
      # This method ensures it's removed from the old collections.
      def add_to_collections(new_collection_ids)
        return true if new_collection_ids.nil?
        #remove from old collections
        (curation_concern.collection_ids - new_collection_ids).each do |old_id|
          Collection.find(old_id).members.delete(curation_concern)
        end

        #add to new
        curation_concern.collection_ids = new_collection_ids
        true
      end

      def assign_representative
        curation_concern.representative = curation_concern.generic_file_ids.first
        curation_concern.save
      end

      private
      def attach_file(file)
        generic_file = Worthwhile::GenericFile.new
        generic_file.file = file
        generic_file.batch = curation_concern
        Sufia::GenericFile::Actions.create_metadata(
          generic_file, user, curation_concern.pid
        )
        generic_file.embargo_release_date = curation_concern.embargo_release_date
        generic_file.visibility = visibility
        CurationConcern.attach_file(generic_file, user, file)
      end


      def valid_file?(file_path)
        return file_path.present? && File.exists?(file_path) && !File.zero?(file_path)
      end
    end
  end
end
