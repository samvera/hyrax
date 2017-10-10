module Hyrax
  # Attaches remote files to the work
  class CreateWithRemoteFilesActor < Hyrax::Actors::AbstractActor
    def create(attributes)
      remote_files = attributes.delete(:remote_files)
      next_actor.create(attributes) && attach_files(remote_files)
    end

    def update(attributes)
      remote_files = attributes.delete(:remote_files)
      next_actor.update(attributes) && attach_files(remote_files)
    end

    protected

      # @param [HashWithIndifferentAccess] remote_files
      # @return [TrueClass]
      def attach_files(remote_files)
        return true unless remote_files
        remote_files.each do |file_info|
          next if file_info.blank? || file_info[:url].blank?
          unless validate_remote_url(file_info[:url])
            Rails.logger.error "User #{user.user_key} attempted to ingest file from url #{file_info[:url]}, which doesn't pass validation"
            return false
          end
          create_file_from_url(file_info[:url], file_info[:file_name])
        end
        true
      end

      # Generic utility for creating FileSet from a URL
      # Used in to import files using URLs from a file picker like browse_everything
      def create_file_from_url(url, file_name)
        ::FileSet.new(import_url: url, label: file_name) do |fs|
          actor = Hyrax::Actors::FileSetActor.new(fs, user)
          actor.create_metadata(visibility: curation_concern.visibility)
          actor.attach_file_to_work(curation_concern)
          fs.save!
          uri = URI.parse(URI.encode(url))
          if uri.scheme == 'file'
            IngestLocalFileJob.perform_later(fs, URI.decode(uri.path), user)
          else
            ImportUrlJob.perform_later(fs, operation_for(user: actor.user))
          end
        end
      end

      def operation_for(user:)
        Hyrax::Operation.create!(user: user,
                                 operation_type: "Attach Remote File")
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

      def whitelisted_ingest_dirs
        Hyrax.config.whitelisted_ingest_dirs
      end
  end
end
