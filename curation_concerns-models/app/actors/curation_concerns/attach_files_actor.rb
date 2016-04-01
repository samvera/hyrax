module CurationConcerns
  class AttachFilesActor < AbstractActor
    def create(attributes)
      files = [attributes.delete(:files)].flatten.compact
      attach_files(files, visibility_attributes(attributes)) &&
        next_actor.create(attributes)
    end

    def update(attributes)
      files = [attributes.delete(:files)].flatten.compact
      next_actor.update(attributes) &&
        attach_files(files, visibility_attributes(attributes))
    end

    private

      def attach_files(files, visibility_attr)
        files.all? do |file|
          attach_file(file, visibility_attr)
        end
      end

      def attach_file(file, visibility_attr)
        file_set = ::FileSet.new
        file_set_actor = CurationConcerns::FileSetActor.new(file_set, user)
        file_set_actor.create_metadata(curation_concern, visibility_attr)
        file_set_actor.create_content(file)
      end

      # The attributes used for visibility - used to send as initial params to
      # created FileSets.
      def visibility_attributes(attributes)
        attributes.slice(:visibility, :visibility_during_lease,
                         :visibility_after_lease, :lease_expiration_date,
                         :embargo_release_date, :visibility_during_embargo,
                         :visibility_after_embargo)
      end
  end
end
