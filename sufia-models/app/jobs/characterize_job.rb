class CharacterizeJob < ActiveFedoraIdBasedJob
  def queue_name
    :characterize
  end

  def run
    Sufia::CharacterizationService.run(generic_file)
    generic_file.save
    Sufia.queue.push(CreateDerivativesJob.new(generic_file.id))
  end
end
