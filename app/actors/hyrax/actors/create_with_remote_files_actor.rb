module Hyrax
  module Actors
    # If there is a key `:remote_files' in the attributes, it attaches the files at the specified URIs
    # to the work. e.g.:
    #     attributes[:remote_files] = filenames.map do |name|
    #       { url: "https://example.com/file/#{name}", file_name: name }
    #     end
    class CreateWithRemoteFilesActor < Hyrax::Actors::AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        remote_files = env.attributes.delete(:remote_files)
        next_actor.create(env) && attach_files(env, remote_files)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        remote_files = env.attributes.delete(:remote_files)
        next_actor.update(env) && attach_files(env, remote_files)
      end

      private

        def whitelisted_ingest_dirs
          Hyrax.config.whitelisted_ingest_dirs
        end

        def validate_remote_url(url)
          uri = URI.parse(URI.encode(url))
          if uri.scheme == 'file'
            path = File.absolute_path(URI.decode(uri.path))
            whitelisted_ingest_dirs.any? do |dir|
              path.start_with?(dir) && path.length > dir.length
            end
          else
            # TODO: It might be a good idea to validate other URLs as well.
            #       The server can probably access URLs the user can't.
            true
          end
        end

        # @param [HashWithIndifferentAccess] remote_files
        # @return [TrueClass]
        def attach_files(env, remote_files)
          return true unless remote_files
          remote_files.each do |file_info|
            next if file_info.blank? || file_info[:url].blank?
            unless validate_remote_url(file_info[:url])
              Rails.logger.error "User #{env.user.user_key} attempted to ingest file from url #{file_info[:url]}, which doesn't pass validation"
              return false
            end
            create_file_from_url(env, file_info[:url], file_info[:file_name])
          end
          true
        end

        # Generic utility for creating FileSet from a URL
        # Used in to import files using URLs from a file picker like browse_everything
        def create_file_from_url(env, url, file_name)
          ::FileSet.new(import_url: url, label: file_name) do |fs|
            actor = Hyrax::Actors::FileSetActor.new(fs, env.user)
            actor.create_metadata(visibility: env.curation_concern.visibility)
            actor.attach_to_work(env.curation_concern)
            Valkyrie::MetadataAdapter.find(:indexing_persister).persister(resource: fs)
            uri = URI.parse(URI.encode(url))
            if uri.scheme == 'file'
              IngestLocalFileJob.perform_later(fs, URI.decode(uri.path), env.user)
            else
              ImportUrlJob.perform_later(fs, operation_for(user: actor.user))
            end
          end
        end

        def operation_for(user:)
          Hyrax::Operation.create!(user: user,
                                   operation_type: "Attach Remote File")
        end
    end
  end
end
