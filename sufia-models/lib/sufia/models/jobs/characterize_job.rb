class CharacterizeJob < ActiveFedoraPidBasedJob

  def queue_name
    :characterize
  end

  def run
    generic_file.characterize
    after_characterize
  end

  def after_characterize
    if generic_file.pdf? || generic_file.image? || generic_file.video?
      generic_file.create_thumbnail
    end
    if generic_file.video?
      Sufia.queue.push(TranscodeVideoJob.new(generic_file_id))
    elsif generic_file.audio?
      Sufia.queue.push(TranscodeAudioJob.new(generic_file_id))
    end
  end
end
