class CharacterizeJob < ActiveJob::Base
  queue_as CurationConcerns.config.ingest_queue_name

  # @param [FileSet] file_set
  # @param [String] filename a local path for the file to characterize so we don't have to pull a copy out of fedora.
  def perform(file_set, filename)
    raise LoadError, "#{file_set.class.characterization_proxy} was not found" unless file_set.characterization_proxy?
    Hydra::Works::CharacterizationService.run(file_set.characterization_proxy, filename)
    file_set.characterization_proxy.save!
    file_set.update_index
    CreateDerivativesJob.perform_later(file_set, filename)
  end
end
