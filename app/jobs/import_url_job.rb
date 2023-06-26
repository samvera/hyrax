# frozen_string_literal: true
require 'uri'
require 'tmpdir'
require 'browse_everything/retriever'

##
# Given a {FileSet} that has an +#import_url+ property, download that file and
# deposit into Fedora.
#
# @note this is commonly called during deposit by {AttachFilesToWorkJob} (when
#   files are uploaded directly as {Hyrax::UploadedFile}) and
#   {Hyrax::Actors::CreateWithRemoteFilesActor} when files are located in
#   some other service.
class ImportUrlJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name
  attr_reader :file_set, :operation, :headers, :user, :uri

  before_enqueue do |job|
    operation = job.arguments[1]
    operation.pending_job(job)
  end

  ##
  # @param [FileSet] file_set
  # @param [Hyrax::BatchCreateOperation] operation
  # @param [Hash] headers - header data to use in interaction with remote url
  # @param [Boolean] use_valkyrie - a switch on whether or not to use Valkyrie processing
  #
  # @todo At present, this job works for ActiveFedora objects. The use_valkyrie is not complete.
  def perform(file_set, operation, headers = {}, use_valkyrie: false)
    @file_set = file_set
    @operation = operation
    @headers = headers
    operation.performing!
    @user = User.find_by_user_key(file_set.depositor)
    @uri = URI(file_set.import_url)

    return false unless can_retrieve_remote?

    if use_valkyrie
      # TODO
    else
      perform_af
    end
  end

  private

  def can_retrieve_remote?
    return true if BrowseEverything::Retriever.can_retrieve?(uri, headers)
    send_error('Expired URL')
    false
  end

  def perform_af
    name = file_set.label

    # @todo Use Hydra::Works::AddExternalFileToFileSet instead of manually
    #       copying the file here. This will be gnarly.
    copy_remote_file(name) do |f|
      # reload the FileSet once the data is copied since this is a long running task
      file_set.reload

      # FileSetActor operates synchronously so that this tempfile is available.
      # If asynchronous, the job might be invoked on a machine that did not have this temp file on its file system!
      # NOTE: The return status may be successful even if the content never attaches.
      log_import_status(f)
    end
  end

  # Download file from uri, yields a block with a file in a temporary directory.
  # It is important that the file on disk has the same file name as the URL,
  # because when the file in added into Fedora the file name will get persisted in the
  # metadata.
  # @param name [String] the human-readable name of the file
  # @yield [IO] the stream to write to
  def copy_remote_file(name)
    filename = File.basename(name)
    dir = Dir.mktmpdir
    Hyrax.logger.debug("ImportUrlJob: Copying <#{uri}> to #{dir}")

    File.open(File.join(dir, filename), 'wb') do |f|
      write_file(f)
      yield f
    rescue StandardError => e
      send_error(e.message)
    end
    Hyrax.logger.debug("ImportUrlJob: Closing #{File.join(dir, filename)}")
  end

  ##
  # Send message to user on download failure
  #
  # @param error_message [String] the download error message
  def send_error(error_message)
    file_set.errors.add('Error:', error_message)
    Hyrax.config.callback.run(:after_import_url_failure, file_set, user, warn: false)
    operation.fail!(file_set.errors.full_messages.join(' '))
  end

  # Write file to the stream
  # @param f [IO] the stream to write to
  def write_file(f)
    retriever = BrowseEverything::Retriever.new
    uri_spec = ActiveSupport::HashWithIndifferentAccess.new(url: uri, headers: headers)
    retriever.retrieve(uri_spec) do |chunk|
      f.write(chunk)
    end
    f.rewind
  end

  # Set the import operation status
  # @param f [IO] the stream to write to
  def log_import_status(f)
    if Hyrax::Actors::FileSetActor.new(file_set, user).create_content(f, from_url: true)
      operation.success!
    else
      send_error(uri.path)
    end
  end
end
