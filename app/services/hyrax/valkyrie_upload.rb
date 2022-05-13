# frozen_string_literal: true

module Hyrax::ValkyrieUpload
  # @param [IO] io
  # @param [String] filename
  # @param [Hyrax::FileSet] file_set
  # @param [RDF::URI] use
  # @param [User] user
  #
  # @see Hyrax::FileMetadata::Use
  # @return [Hyrax::FileMetadata] the metadata representing the uploaded file
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/ParameterLists
  def self.file(
    filename:,
    file_set:,
    io:,
    storage_adapter: Hyrax.storage_adapter,
    use: Hyrax::FileMetadata::Use::ORIGINAL_FILE,
    user: nil
  )

    streamfile = storage_adapter.upload(
      file: io,
      original_filename: filename,
      resource: file_set
    )

    file_metadata = Hyrax::FileMetadata.new(
      label: filename,
      original_filename: filename,
      use: [use],
      file_set_id: file_set.id,
      file_identifier: streamfile.id
    )

    case use
    when Hyrax::FileMetadata::Use::ORIGINAL_FILE
      # Set file set label.
      reset_title = file_set.title.first == file_set.label
      # set title to label if that's how it was before this characterization
      file_set.title = file_metadata.original_filename if reset_title
      # always set the label to the original_name
      file_set.label = file_metadata.original_filename
    when Hyrax::FileMetadata::Use::THUMBNAIL
      # TODO: the parent work's thumbnail_id remains incorrect (it's set to the
      # FileSet ID, rather than the ID of this thumbnail FileMetadata; but
      # trying to update the parent attributes here doesn't seem to stick
      file_set.thumbnail_id = file_metadata.id
    end
    saved_metadata = Hyrax.persister.save(resource: file_metadata)
    Hyrax.publisher.publish("object.file.uploaded", metadata: saved_metadata)

    add_file_to_file_set(file_set: file_set,
                         file_metadata: saved_metadata,
                         user: user)

    Hyrax.publisher.publish('file.metadata.updated', metadata: saved_metadata, user: user)

    saved_metadata
  end

  # @param [Hyrax::FileSet] file_set the file set to add to
  # @param [Hyrax::FileMetadata] file_metadata the metadata object representing
  #   the file to add
  # @param [::User] user  the user performing the add
  #
  # @return [Hyrax::FileSet] updated file set
  def self.add_file_to_file_set(file_set:, file_metadata:, user:)
    file_set.file_ids << file_metadata.id
    set_file_use_ids(file_set, file_metadata)

    Hyrax.persister.save(resource: file_set)
    Hyrax.publisher.publish('object.membership.updated', object: file_set, user: user)
  end

  # @api private
  # @param [Hyrax::FileSet] file_set the file set to add to
  # @param [Hyrax::FileMetadata] file_metadata the metadata object representing
  #   the file to add
  # @return [void]
  def self.set_file_use_ids(file_set, file_metadata)
    file_metadata.type.each do |type|
      case type
      when Hyrax::FileMetadata::Use::ORIGINAL_FILE
        file_set.original_file_id = file_metadata.id
      when Hyrax::FileMetadata::Use::THUMBNAIL
        file_set.thumbnail_id = file_metadata.id
      when Hyrax::FileMetadata::Use::EXTRACTED_TEXT
        file_set.extracted_text_id = file_metadata.id
      else
        Rails.logger.warn "Unknown file use #{file_metadata.type} specified for #{file_metadata.file_identifier}"
      end
    end
  end
end
