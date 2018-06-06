module Hyrax
  module Actors
    # Creates a work and attaches files to the work
    class CreateWithFilesOrderedMembersActor < CreateWithFilesActor
      # @return [TrueClass]
      def attach_files(files, env)
        return true if files.blank?
        AttachFilesToWorkWithOrderedMembersJob.perform_later(env.curation_concern, files, env.attributes.to_h.symbolize_keys)
        true
      end
    end
  end
end
