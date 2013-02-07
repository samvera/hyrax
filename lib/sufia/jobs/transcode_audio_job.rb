# Created by: Justin Coyne
# 7 Feb 2013
# An asyncronous job for transcoding audio files using FFMpeg

class TranscodeAudioJob < FfmpegTranscodeJob
  def queue_name
    :audio
  end

  def process
    encode_mp3()
    encode_ogg()
  end

  private 
    def encode_ogg
      opts = ""
      encode_datastream('ogg', 'audio/ogg', opts)
    end

    def encode_mp3
      opts = ""
      encode_datastream('mp3', 'audio/mp3', opts)
    end


end

