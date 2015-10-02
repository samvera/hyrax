class CharacterizeJob < ActiveFedoraIdBasedJob
  queue_as :characterize

  # @param [String] id
  # @param [String] filename a local path for the file to characterize. By using this, we don't have to pull a copy out of fedora.
  def perform(id, filename)
    @id = id
    CurationConcerns::CharacterizationService.run(generic_file, filename)
    generic_file.save
    FulltextExtractionJob.perform_later(generic_file.id, filename)
    CreateDerivativesJob.perform_later(generic_file.id, filename)
  end
end
