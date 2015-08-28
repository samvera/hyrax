class CreateDerivativesJob < ActiveFedoraIdBasedJob
  queue_as :derivatives

  def perform(id)
    @id = id
    return unless generic_file.original_file.has_content?
    return unless CurationConcerns.config.enable_ffmpeg if generic_file.video?

    generic_file.create_derivatives
    generic_file.save
  end
end
