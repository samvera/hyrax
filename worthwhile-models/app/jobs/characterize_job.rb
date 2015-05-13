class CharacterizeJob < ActiveFedoraIdBasedJob
  def queue_name
    :characterize
  end

  def run
    generic_file.characterize
    Sufia.queue.push(CreateDerivativesJob.new(generic_file.id))
  end
end
