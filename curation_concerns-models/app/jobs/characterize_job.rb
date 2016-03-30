class CharacterizeJob < ActiveJob::Base
  queue_as :characterize

  # @param [FileSet] file_set
  # @param [String] filename a local path for the file to characterize. By using this, we don't have to pull a copy out of fedora.
  def perform(file_set, filename)
    Hydra::Works::CharacterizationService.run(file_set, filename)
    file_set.save!
    CreateDerivativesJob.perform_later(file_set, filename)
  end
end
