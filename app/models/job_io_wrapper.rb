# frozen_string_literal: true
# Primarily for jobs like IngestJob to revivify an equivalent FileActor to one that existed on
# the caller's side of an asynchronous Job invocation.  This involves providing slots
# for the metadata that might travel w/ the actor's various supported types of @file.
# For example, we cannot just do:
#
#   SomeJob.perform_later(arg1, arg2, File.new('/path/to/file'))
#
# Because we'll get:
#
#   ActiveJob::SerializationError: Unsupported argument type: File
#
# This also applies to Hydra::Derivatives::IoDecorator, Tempfile, etc., pretty much any IO.
#
# @note Along with user and file_set_id, path or uploaded_file are required.
#  If both are provided: path is used preferentially for access IF it exists;
#  however, the uploaded_file is used preferentially for default original_name and mime_type,
#  because it already has that information.
class JobIoWrapper < ApplicationRecord
  belongs_to :user, optional: false
  belongs_to :uploaded_file, optional: true, class_name: 'Hyrax::UploadedFile'
  validates :uploaded_file, presence: true, if: proc { |x| x.path.blank? }
  validates :file_set_id, presence: true

  after_initialize :static_defaults
  delegate :read, to: :file

  # Responsible for creating a JobIoWrapper from the given parameters, with a
  # focus on sniffing out attributes from the given :file.
  #
  # @param [User] user - The user requesting to create this instance
  # @param [#path, Hyrax::UploadedFile] file - The file that is to be uploaded
  # @param [String] relation
  # @param [FileSet] file_set - The associated file set
  # @return [JobIoWrapper]
  # @raise ActiveRecord::RecordInvalid - if the instance is not valid
  def self.create_with_varied_file_handling!(user:, file:, relation:, file_set:)
    args = { user: user, relation: relation.to_s, file_set_id: file_set.id }
    if file.is_a?(Hyrax::UploadedFile)
      args[:uploaded_file] = file
      args[:path] = file.uploader.path
    elsif file.respond_to?(:path)
      args[:path] = file.path
      args[:original_name] = file.original_filename if file.respond_to?(:original_filename)
      args[:original_name] ||= file.original_name if file.respond_to?(:original_name)
    else
      raise "Require Hyrax::UploadedFile or File-like object, received #{file.class} object: #{file}"
    end
    create!(args)
  end

  def original_name
    super || extracted_original_name
  end

  def mime_type
    super || extracted_mime_type
  end

  def size
    return file.size.to_s if file.respond_to? :size
    return file.stat.size.to_s if file.respond_to? :stat
    nil # unable to determine
  end

  def file_set(use_valkyrie: Hyrax.config.query_index_from_valkyrie)
    return FileSet.find(file_set_id) unless use_valkyrie
    Hyrax.query_service.find_by(id: Valkyrie::ID.new(file_set_id))
  end

  def file_actor
    Hyrax::Actors::FileActor.new(file_set, relation.to_sym, user)
  end

  # @return [Hyrax::FileMetadata, FalseClass] the created file metadata on success, false on failure
  def ingest_file
    file_actor.ingest_file(self)
  end

  def to_file_metadata
    Hyrax::FileMetadata.new(label: original_name,
                            original_filename: original_name,
                            mime_type: mime_type,
                            use: [Hyrax::FileMetadata::Use::ORIGINAL_FILE])
  end

  # The magic that switches *once* between local filepath and CarrierWave file
  # @return [File, StringIO, #read] File-like object ready to #read
  def file
    @file ||= (file_from_path || file_from_uploaded_file!)
  end

  private

  def extracted_original_name
    eon = uploaded_file.uploader.filename if uploaded_file
    eon ||= File.basename(path) if path.present? # NOTE: uploader.filename is `nil` with uncached remote files (e.g. AWSFile)
    eon
  end

  def extracted_mime_type
    uploaded_file ? uploaded_file.uploader.content_type : Hydra::PCDM::GetMimeTypeForFile.call(original_name)
  end

  # @return [File, StringIO] depending on CarrierWave configuration
  # @raise when uploaded_file *becomes* required but is missing
  def file_from_uploaded_file!
    raise("path '#{path}' was unusable and uploaded_file empty") unless uploaded_file
    self.path = uploaded_file.uploader.file.path # old path useless now
    uploaded_file.uploader.sanitized_file.file
  end

  # @return [File, nil] nil if the path doesn't exist on this (worker) system or can't be read
  def file_from_path
    File.open(path, 'rb') if path && File.exist?(path) && File.readable?(path)
  end

  def static_defaults
    self.relation ||= 'original_file'
  end
end
