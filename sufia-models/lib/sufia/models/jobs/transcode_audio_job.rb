# Created by: Justin Coyne
# 7 Feb 2013
# An asyncronous job for transcoding audio files using FFMpeg

class TranscodeAudioJob < ActiveFedoraPidBasedJob
  def queue_name
    :audio
  end

  def run
    generic_file.create_derivatives
    generic_file.save
  end

end
