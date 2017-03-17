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
  end
end
