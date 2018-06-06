module Hyrax
  module Actors
    # If there is a key `:remote_files' in the attributes, it attaches the files at the specified URIs
    # to the work. e.g.:
    #     attributes[:remote_files] = filenames.map do |name|
    #       { url: "https://example.com/file/#{name}", file_name: name }
    #     end
    #
    # Browse everything may also return a local file. And although it's in the
    # url property, it may have spaces, and not be a valid URI.
    class CreateWithRemoteFilesOrderedMembersActor < CreateWithRemoteFilesActor
      attr_reader :ordered_members

      # @param [HashWithIndifferentAccess] remote_files
      # @return [TrueClass]
      def attach_files(env, remote_files)
        return true unless remote_files
        @ordered_members = env.curation_concern.ordered_members.to_a
        remote_files.each do |file_info|
          next if file_info.blank? || file_info[:url].blank?
          # Escape any space characters, so that this is a legal URI
          uri = URI.parse(Addressable::URI.escape(file_info[:url]))
          unless validate_remote_url(uri)
            Rails.logger.error "User #{env.user.user_key} attempted to ingest file from url #{file_info[:url]}, which doesn't pass validation"
            return false
          end
          auth_header = file_info.fetch(:auth_header, {})
          create_file_from_url(env, uri, file_info[:file_name], auth_header)
        end
        add_ordered_members(env.user, env.curation_concern)
        true
      end

      # Generic utility for creating FileSet from a URL
      # Used in to import files using URLs from a file picker like browse_everything
      def create_file_from_url(env, uri, file_name, auth_header = {})
        ::FileSet.new(import_url: uri.to_s, label: file_name) do |fs|
          actor = file_set_actor_class.new(fs, env.user)
          actor.create_metadata(visibility: env.curation_concern.visibility)
          actor.attach_to_work(env.curation_concern)
          fs.save!
          ordered_members << fs
          if uri.scheme == 'file'
            # Turn any %20 into spaces.
            file_path = CGI.unescape(uri.path)
            IngestLocalFileJob.perform_later(fs, file_path, env.user)
          else
            ImportUrlJob.perform_later(fs, operation_for(user: actor.user), auth_header)
          end
        end
      end

      # Add all file_sets as ordered_members in a single action
      def add_ordered_members(user, work)
        actor = Hyrax::Actors::OrderedMembersActor.new(ordered_members, user)
        actor.attach_ordered_members_to_work(work)
      end

      class_attribute :file_set_actor_class
      self.file_set_actor_class = Hyrax::Actors::FileSetOrderedMembersActor
    end
  end
end
