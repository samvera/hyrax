module CurationConcerns
  class AttachFilesActor < AbstractActor
    attr_reader :next_actor
    def initialize(curation_concern, user, attributes, more_actors)
      @files = [attributes.delete(:files)].flatten.compact
      super
    end

    def create
      attach_files && next_actor.create
    end

    def update
      next_actor.update && attach_files
    end

    private

      def attach_files
        @files.all? do |file|
          attach_file(file)
        end
      end

      def attach_file(file)
        file_set = ::FileSet.new
        file_set_actor = CurationConcerns::FileSetActor.new(file_set, user)
        file_set_actor.create_metadata(curation_concern, visibility_attributes)
        file_set_actor.create_content(file)
      end

      # The attributes used for visibility - used to send as initial params to
      # created FileSets.
      def visibility_attributes
        attributes.slice(:visibility, :visibility_during_lease,
                         :visibility_after_lease, :lease_expiration_date,
                         :embargo_release_date, :visibility_during_embargo,
                         :visibility_after_embargo)
      end
  end
end
