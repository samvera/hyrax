module Sufia
  # Creates a work and attaches files to the work
  class CreateWithFilesActor < CurationConcerns::Actors::AbstractActor
    def create(attributes)
      self.uploaded_file_ids = attributes.delete(:uploaded_files)
      validate_files && mark_inactive && next_actor.create(attributes) && attach_files
    end

    def update(attributes)
      self.uploaded_file_ids = attributes.delete(:uploaded_files)
      validate_files && next_actor.update(attributes) && attach_files
    end

    protected

      attr_reader :uploaded_file_ids
      def uploaded_file_ids=(input)
        @uploaded_file_ids = Array.wrap(input).select(&:present?)
      end

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
        return [] if uploaded_file_ids.empty?
        @uploaded_files ||= UploadedFile.find(uploaded_file_ids)
      end

      def mark_inactive
        return true unless Flipflop.enable_mediated_deposit?
        curation_concern.state = inactive_uri
      end

      def inactive_uri
        ::RDF::URI('http://fedora.info/definitions/1/0/access/ObjState#inactive')
      end
  end
end
