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
      if generic_file.mime_type == 'audio/ogg'
        # Don't re-encode, just copy
        generic_file.add_file_datastream(generic_file.content.read, :dsid=>'ogg', :mimeType=>'audio/ogg')
        #generic_file.content.rewind
      else
        encode_datastream('ogg', 'audio/ogg', opts)
      end
    end

    def encode_mp3
      opts = ""
      if generic_file.mime_type == 'audio/mpeg'
        # Don't re-encode, just copy
        generic_file.add_file_datastream(generic_file.content.read, :dsid=>'mp3', :mimeType=>'audio/mp3')
        #generic_file.content.rewind
      else
        encode_datastream('mp3', 'audio/mp3', opts)
      end
    end


end

