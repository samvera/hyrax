# Characterizes the file at 'filepath' if available, otherwise, pulls a copy from the repository
# and runs characterization on that file.

class CharacterizeJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  def perform(work)
    Hyrax::Characterizer.for(source: work).characterize
  end
end
