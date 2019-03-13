require 'uri'
require 'tmpdir'
require 'browse_everything/retriever'

# Given a FileSet that has an import_url property,
# download that file and put it into Fedora
# Called by AttachFilesToWorkJob (when files are uploaded to s3)
# and CreateWithRemoteFilesActor when files are located in some other service.
class ImportUrlJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name
  attr_reader :file_set, :operation

  before_enqueue do |job|
    operation = job.arguments[1]
    operation.pending_job(job)
  end

  # @param [FileSet] file_set
  # @param [Hyrax::BatchCreateOperation] operation
  def perform(file_set, operation, headers = {})
    operation.performing!
    user = User.find_by_user_key(file_set.depositor)
    uri = URI(file_set.import_url)
    name = file_set.label

    @file_set = file_set
    @operation = operation

    unless BrowseEverything::Retriever.can_retrieve?(uri, headers)
      send_error('Expired URL')
      return false
    end

    # @todo Use Hydra::Works::AddExternalFileToFileSet instead of manually
    #       copying the file here. This will be gnarly.
    copy_remote_file(uri, name, headers) do |f|
      # reload the FileSet once the data is copied since this is a long running task
      file_set.reload

      # FileSetActor operates synchronously so that this tempfile is available.
      # If asynchronous, the job might be invoked on a machine that did not have this temp file on its file system!
      # NOTE: The return status may be successful even if the content never attaches.
      log_import_status(uri, f, user)
    end
  end

  private

    # Download file from uri, yields a block with a file in a temporary directory.
    # It is important that the file on disk has the same file name as the URL,
    # because when the file in added into Fedora the file name will get persisted in the
    # metadata.
    # @param uri [URI] the uri of the file to download
    # @param name [String] the human-readable name of the file
    # @param headers [Hash] the HTTP headers for the GET request (these may contain an authentication token)
    # @yield [IO] the stream to write to
    def copy_remote_file(uri, name, headers = {})
      filename = File.basename(name)
      dir = Dir.mktmpdir
      Rails.logger.debug("ImportUrlJob: Copying <#{uri}> to #{dir}")

      File.open(File.join(dir, filename), 'wb') do |f|
        begin
          write_file(uri, f, headers)
          yield f
        rescue StandardError => e
          send_error(e.message)
        end
      end
      Rails.logger.debug("ImportUrlJob: Closing #{File.join(dir, filename)}")
    end

    # Send message to user on download failure
    # @param filename [String] the filename of the file to download
    # @param error_message [String] the download error message
    def send_error(error_message)
      user = User.find_by_user_key(file_set.depositor)
      @file_set.errors.add('Error:', error_message)
      Hyrax.config.callback.run(:after_import_url_failure, @file_set, user)
      @operation.fail!(@file_set.errors.full_messages.join(' '))
    end

    # Write file to the stream
    # @param uri [URI] the uri of the file to download
    # @param f [IO] the stream to write to
    def write_file(uri, f, headers)
      retriever = BrowseEverything::Retriever.new
      uri_spec = ActiveSupport::HashWithIndifferentAccess.new(url: uri, headers: headers)
      retriever.retrieve(uri_spec) do |chunk|
        f.write(chunk)
      end
      f.rewind
    end

    # Set the import operation status
    # @param uri [URI] the uri of the file to download
    # @param f [IO] the stream to write to
    # @param user [User]
    def log_import_status(uri, f, user)
      if Hyrax::Actors::FileSetActor.new(@file_set, user).create_content(f, from_url: true)
        operation.success!
      else
        send_error(uri.path, nil)
      end
    end
end
