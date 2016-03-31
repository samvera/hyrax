module Sufia
  # Creates a work and attaches files to the work
  class CreateWithFilesActor
    attr_reader :work_actor, :uploaded_file_ids

    def initialize(work_actor, uploaded_file_ids)
      @work_actor = work_actor
      @uploaded_file_ids = uploaded_file_ids
    end

    delegate :visibility_changed?, to: :work_actor

    def create
      validate_files && work_actor.create && attach_files
    end

    def update
      validate_files && work_actor.update && attach_files
    end

    protected

      # ensure that the files we are given are owned by the depositor of the work
      def validate_files
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
        AttachFilesToWorkJob.perform_later(work_actor.curation_concern, uploaded_files)
        true
      end

      # Fetch uploaded_files from the database
      def uploaded_files
        return [] unless uploaded_file_ids
        @uploaded_files ||= UploadedFile.find(uploaded_file_ids)
      end
  end
end
