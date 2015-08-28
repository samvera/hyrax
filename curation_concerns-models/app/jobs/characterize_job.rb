class CharacterizeJob < ActiveFedoraIdBasedJob
  queue_as :characterize

  def perform(id)
    @id = id
    CurationConcerns::CharacterizationService.run(generic_file)
    generic_file.save
    CreateDerivativesJob.perform_later(generic_file.id)
  end
end
