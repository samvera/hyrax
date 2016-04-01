module Sufia
  # Creates a work and attaches files to the work
  class CreateWithCollectionsActor
    attr_reader :work_actor, :collection_ids

    def initialize(work_actor, collection_ids)
      @work_actor = work_actor
      @collection_ids = collection_ids
    end

    delegate :visibility_changed?, to: :work_actor

    def create
      validate_collections && work_actor.create && add_to_collections
    end

    def update
      validate_collections && work_actor.update && add_to_collections
    end

    protected

      # ensure that the collections we are given are owned by the depositor of the work
      def validate_collections
        expected_user_id = work_actor.user.id
        uploaded_files.each do |file|
          if file.user_id != expected_user_id
            Rails.logger.error "User #{work_actor.user.user_key} attempted to ingest uploaded_file #{file.id}, but it belongs to a different user"
            return false
          end
        end
        true
      end

      # @return [TrueClass]
      def attach_files
        AddWorkToCollectionJob.perform_later(work_actor.curation_concern, uploaded_files)
        true
      end

      # Fetch collections from Fedora
      def collections
        return [] unless collection_ids
        @collections ||= Collection.find(collection_ids)
      end
  end
end
