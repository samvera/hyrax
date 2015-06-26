class CreateDerivativesJob < ActiveFedoraIdBasedJob
  def queue_name
    :derivatives
  end

  def run
    return unless generic_file.content.has_content?
    if generic_file.video?
      return unless Sufia.config.enable_ffmpeg
    end
    CurationConcerns::CreateDerivativesService.run(generic_file)
    generic_file.save
  end
end
