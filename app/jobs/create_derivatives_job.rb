# frozen_string_literal: true
class CreateDerivativesJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  # @param [FileSet] file_set
  # @param [String] file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the Hyrax.config.working_path
  def perform(file_set, file_id, filepath = nil)
    return if file_set.video? && !Hyrax.config.enable_ffmpeg

    # Ensure a fresh copy of the repo file's latest version is being worked on, if no filepath is directly provided
    filepath = Hyrax::WorkingDirectory.copy_repository_resource_to_working_directory(Hydra::PCDM::File.find(file_id), file_set.id) unless filepath && File.exist?(filepath)

    file_set.create_derivatives(filepath)

    # Reload from Fedora and reindex for thumbnail and extracted text
    file_set.reload
    file_set.update_index
    file_set.parent.update_index if parent_needs_reindex?(file_set)
  end

  # If this file_set is the thumbnail for the parent work,
  # then the parent also needs to be reindexed.
  def parent_needs_reindex?(file_set)
    return false unless file_set.parent
    file_set.parent.thumbnail_id == file_set.id
  end
end
