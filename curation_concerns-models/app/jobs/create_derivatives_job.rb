class CreateDerivativesJob < ActiveFedoraIdBasedJob
  queue_as :derivatives

  def perform(id, file_name)
    @id = id
    return if generic_file.video? && !CurationConcerns.config.enable_ffmpeg

    generic_file.create_derivatives(file_name)
  end
end
