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
  # This object is a shim to address the implementation details of the
  # internal methods of the ImportUrlJob class.  Prior to adding this
  # shim, the ImportUrlJob operated on a file_set, with the assumption
  # that it had an `#errors` method and a `#reload` method.
  class FileSetWrapper < SimpleDelegator
    def initialize(object:)
      @object = object
      super(@object)
      case object
      when ActiveFedora::Base
        @error_container_builder = ->(obj) { obj }
        @reloader = ->(obj) { obj.reload }
        @use_valkyrie = false
      else
        @error_container_builder = Hyrax::ChangeSet.method(:for)
        @reloader = ->(obj) { Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: obj.id) }
        @use_valkyrie = true
      end
      build_error_container!
    end

    def wrapped_object
      @object
    end

    def reload
      @object = @reloader.call(@object)
      build_error_container!
      @object
    end

    def errors
      @error_container.errors
    end

    def use_valkyrie?
      @use_valkyrie
    end

    private

    def build_error_container!
      @error_container = @error_container_builder.call(@object)
    end
  end
  private_constant :FileSetWrapper

  queue_as Hyrax.config.ingest_queue_name
  attr_reader :file_set, :operation, :headers, :user, :uri

  before_enqueue do |job|
    operation = job.arguments[1]
    operation.pending_job(job)
  end

  ##
  # @param file_set [Hyrax::FileSet, FileSet] a persisted file_set object
  # @param operation [Hyrax::BatchCreateOperation]
  # @param headers [Hash] header data to use in interaction with remote url
  #
  # @todo At present, this job works for ActiveFedora objects. The use_valkyrie is not complete.
  def perform(file_set, operation, headers = {})
    @file_set = file_set
    wrapper = FileSetWrapper.new(object: @file_set)
    @operation = operation
    @headers = headers
    operation.performing!
    @user = User.find_by_user_key(file_set.depositor)
    @uri = URI(file_set.import_url)

    return false unless can_retrieve_remote?(wrapper: wrapper)

    __perform(wrapper: wrapper)
  end

  private

  def can_retrieve_remote?(wrapper:)
    return true if BrowseEverything::Retriever.can_retrieve?(uri, headers)
    send_error(message: 'Expired URL', wrapper: wrapper)
    false
  end

  def __perform(wrapper:)
    name = wrapper.label

    # @todo Use Hydra::Works::AddExternalFileToFileSet instead of manually
    #       copying the file here. This will be gnarly.
    copy_remote_file(name: name, wrapper: wrapper) do |io_stream|
      # reload the FileSet once the data is copied since this is a long running task
      wrapper.reload

      # FileSetActor operates synchronously so that this tempfile is available.
      # If asynchronous, the job might be invoked on a machine that did not have this temp file on its file system!
      # NOTE: The return status may be successful even if the content never attaches.
      log_import_status(io_stream: io_stream, wrapper: wrapper)
    end
  end

  # Download file from uri, yields a block with a file in a temporary directory.
  # It is important that the file on disk has the same file name as the URL,
  # because when the file in added into Fedora the file name will get persisted in the
  # metadata.
  # @param name [String] the human-readable name of the file
  # @param wrapper [FileSetWrapper]
  # @yield [IO] the stream to write to
  def copy_remote_file(name:, wrapper:)
    filename = File.basename(name)
    dir = Dir.mktmpdir
    Rails.logger.debug("ImportUrlJob: Copying <#{uri}> to #{dir}")

    File.open(File.join(dir, filename), 'wb') do |f|
      begin
        write_file(f)
        yield f
      rescue StandardError => e
        send_error(message: e.message, wrapper: wrapper)
      end
    end
    Rails.logger.debug("ImportUrlJob: Closing #{File.join(dir, filename)}")
  end

  ##
  # Send message to user on download failure
  #
  # @param message [String] the download error message
  # @param wrapper [FileSetWrapper]
  def send_error(message:, wrapper:)
    wrapper.errors.add('Error:', message)

    # I'm a little concerned about passing the wrapped object instead
    # of the wrapper; Namely because there was a presupposition about
    # the original wrapped_object having an `errors` method.
    Hyrax.config.callback.run(:after_import_url_failure, wrapper, user, warn: false)
    operation.fail!(wrapper.errors.full_messages)
  end

  # Write file to the stream
  # @param io_stream [IO] the stream to write to
  def write_file(io_stream)
    retriever = BrowseEverything::Retriever.new
    uri_spec = ActiveSupport::HashWithIndifferentAccess.new(url: uri, headers: headers)
    retriever.retrieve(uri_spec) do |chunk|
      io_stream.write(chunk)
    end
    io_stream.rewind
  end

  # Set the import operation status
  # @param io_stream [IO] the stream to write to
  # @param wrapper [FileSetWrapper]
  def log_import_status(io_stream:, wrapper:)
    if Hyrax::Actors::FileSetActor.new(wrapper.wrapped_object, user, use_valkyrie: wrapper.use_valkyrie?).create_content(io_stream, from_url: true)
      operation.success!
    else
      send_error(message: uri.path, wrapper: wrapper)
    end
  end
end
