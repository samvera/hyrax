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
  delegate :read, :size, to: :file

  def original_name
    super || extracted_original_name
  end

  def mime_type
    super || extracted_mime_type
  end

  def file_set
    FileSet.find(file_set_id)
  end

  def file_actor
    Hyrax::Actors::FileActor.new(file_set, relation.to_sym, user)
  end

  def ingest_file
    file_actor.ingest_file(self)
  end

  private

    def extracted_original_name
      eon = uploaded_file.uploader.filename if uploaded_file
      eon ||= File.basename(path) if path.present? # note: uploader.filename is `nil` with uncached remote files (e.g. AWSFile)
      eon
    end

    def extracted_mime_type
      uploaded_file ? uploaded_file.uploader.content_type : Hydra::PCDM::GetMimeTypeForFile.call(original_name)
    end

    # The magic that switches *once* between local filepath and CarrierWave file
    # @return [#read] File-like object ready to #read
    def file
      @file ||= (file_from_path || file_from_uploaded_file!)
    end

    # @return [File]
    # @raise when uploaded_file *becomes* required but is missing
    def file_from_uploaded_file!
      raise("path '#{path}' was unusable and uploaded_file empty") unless uploaded_file
      self.path = uploaded_file.uploader.file.file # old path useless now
      # uploaded_file.uploader.file.to_file
      uploaded_file.uploader
    end

    # @return [File, nil] nil if the path doesn't exist on this (worker) system or can't be read
    def file_from_path
      File.open(path, 'rb') if path && File.exist?(path) && File.readable?(path)
    end

    def static_defaults
      self.relation ||= 'original_file'
    end
end
