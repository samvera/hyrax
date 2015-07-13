class CharacterizeJob < ActiveFedoraIdBasedJob
  def queue_name
    :characterize
  end

  def run
    Sufia::CharacterizationService.run(generic_file)
    generic_file.save
    CurationConcerns.queue.push(CreateDerivativesJob.new(generic_file.id))
  end
end
