# Created by: Justin Coyne
# 7 Feb 2013
# An asyncronous job for transcoding audio files using FFMpeg

class TranscodeAudioJob
  def queue_name
    :audio
  end

  attr_accessor :generic_file_id

  def initialize(generic_file_id)
    self.generic_file_id = generic_file_id
  end

  def run
    generic_file = GenericFile.find(generic_file_id)
    generic_file.create_derivatives
    generic_file.save
  end

end
