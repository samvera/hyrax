module Sufia
  # Creates a work and attaches files to the work
  class CreateWithFilesActor < CurationConcerns::Actors::AbstractActor
    def create(attributes)
      @uploaded_file_ids = attributes.delete(:uploaded_files)
      validate_files && next_actor.create(attributes) && attach_files
    end

    def update(attributes)
      @uploaded_file_ids = attributes.delete(:uploaded_files)
      validate_files && next_actor.update(attributes) && attach_files
    end

    protected

      # ensure that the files we are given are owned by the depositor of the work
      def validate_files
        expected_user_id = user.id
        uploaded_files.each do |file|
          if file.user_id != expected_user_id
            Rails.logger.error "User #{user.user_key} attempted to ingest uploaded_file #{file.id}, but it belongs to a different user"
            return false
          end
        end
        true
      end

      # @return [TrueClass]
      def attach_files
        return true unless uploaded_files
        AttachFilesToWorkJob.perform_later(curation_concern, uploaded_files)
        true
      end

      # Fetch uploaded_files from the database
      def uploaded_files
        return [] unless @uploaded_file_ids
        @uploaded_files ||= UploadedFile.find(@uploaded_file_ids)
      end
  end
end
