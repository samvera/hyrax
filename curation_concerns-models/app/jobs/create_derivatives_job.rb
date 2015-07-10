class CreateDerivativesJob < ActiveFedoraIdBasedJob
  def queue_name
    :derivatives
  end

  def run
    return unless generic_file.original_file.has_content?
    if generic_file.video?
      return unless CurationConcerns.config.enable_ffmpeg
    end
    CurationConcerns::CreateDerivativesService.run(generic_file)
    generic_file.save
  end
end
