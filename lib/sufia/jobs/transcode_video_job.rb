# Created by: Justin Coyne
# 13 Dec 2012
# An asyncronous job for transcoding video files using FFMpeg

class TranscodeVideoJob < FfmpegTranscodeJob
  def queue_name
    :video
  end

  def process
    encode_mp4()
    encode_webm()
  end

  private 

  def encode_webm
    opts = "#{size_attributes}  -b:v 345k -acodec libvorbis #{audio_attributes}"
    encode_datastream('webm', 'video/webm', opts)
  end

  def encode_mp4
    opts = "#{size_attributes} -b:v 345k -vcodec libx264 -acodec libfaac #{audio_attributes} "
    encode_datastream('mp4', 'video/mp4', opts)
  end


  def size_attributes
    "-s 320x240"
  end

  def audio_attributes 
    "-ac 2 -ab 96k -ar 44100"
  end
end

