class CharacterizeJob < ActiveFedoraIdBasedJob
  def queue_name
    :characterize
  end

  def run
    CurationConcerns::CharacterizationService.run(generic_file)
    generic_file.save
    CurationConcerns.queue.push(CreateDerivativesJob.new(generic_file.id))
  end
end
