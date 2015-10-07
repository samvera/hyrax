class CharacterizeJob < ActiveFedoraIdBasedJob
  queue_as :characterize

  # @param [String] id
  # @param [String] filename a local path for the file to characterize. By using this, we don't have to pull a copy out of fedora.
  def perform(id, filename)
    @id = id
    CurationConcerns::CharacterizationService.run(file_set, filename)
    file_set.save
    CreateDerivativesJob.perform_later(file_set.id, filename)
  end
end
