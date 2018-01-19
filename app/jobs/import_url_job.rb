require 'uri'
require 'tmpdir'
require 'browse_everything/retriever'

# Given a FileSet that has an import_url property,
# download that file and put it into Fedora
# Called by AttachFilesToWorkJob (when files are uploaded to s3)
# and CreateWithRemoteFilesActor when files are located in some other service.
class ImportUrlJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  before_enqueue do |job|
    operation = job.arguments.last
    operation.pending_job(job)
  end

  # @param [FileSet] file_set
  # @param [Hyrax::BatchCreateOperation] operation
  def perform(file_set, operation)
    operation.performing!
    user = User.find_by_user_key(file_set.depositor)
    uri = URI(file_set.import_url)
    # @todo Use Hydra::Works::AddExternalFileToFileSet instead of manually
    #       copying the file here. This will be gnarly.
    copy_remote_file(uri) do |f|
      # reload the FileSet once the data is copied since this is a long running task
      file_set = Hyrax::Queries.find_by(id: file_set.id)

      if create_content(file_set: file_set, file: f, user: user)
        operation.success!
      else
        # send message to user on download failure
        Hyrax.config.callback.run(:after_import_url_failure, file_set, user)
        operation.fail!("Failed to attach file at '#{uri}' to <FileSet id='#{file_set.id}'>'")
      end
    end
  end

  private

    # @param file_set [FileSet]
    # @param file [File]
    # @param user [User]
    # @return [Boolean] true if successfully saved the file.
    def create_content(file_set:, file:, user:)
      # If the file set doesn't have a title or label assigned, set a default.
      update_file_set_title_and_label(file_set: file_set, uri: file_set.import_url)

      wrapper = JobIoWrapper.create_with_varied_file_handling!(user: user,
                                                               file: file,
                                                               relation: Valkyrie::Vocab::PCDMUse.OriginalFile.to_s,
                                                               file_set: file_set)
      file_node = wrapper.ingest_file
      return false unless file_node
      # Copy visibility and permissions from parent (work) to FileSets
      parent_id = file_set.parent.id.to_s
      VisibilityCopyJob.perform_later(parent_id)
      InheritPermissionsJob.perform_later(parent_id)
      true
    end

    def update_file_set_title_and_label(file_set:, uri:)
      return unless file_set.label.nil? || file_set.title.blank?
      file_set.label ||= File.basename(Addressable::URI.parse(uri).path)
      file_set.title = [file_set.label] if file_set.title.blank?

      # Save the updated title and label
      persister.save(resource: file_set)
    end

    def persister
      Valkyrie::MetadataAdapter.find(:indexing_persister).persister
    end

    # Download file from uri, yields a block with a file in a temporary directory.
    # It is important that the file on disk has the same file name as the URL,
    # because when the file in added into Fedora the file name will get persisted in the
    # metadata.
    # @param uri [URI] the uri of the file to download
    # @yield [IO] the stream to write to
    def copy_remote_file(uri)
      filename = File.basename(uri.path)
      Dir.mktmpdir do |dir|
        File.open(File.join(dir, filename), 'wb') do |f|
          retriever = BrowseEverything::Retriever.new
          retriever.retrieve('url' => uri) do |chunk|
            f.write(chunk)
          end
          f.rewind
          yield f
        end
      end
    end
end
