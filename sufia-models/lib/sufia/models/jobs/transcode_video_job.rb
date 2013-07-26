# Created by: Justin Coyne
# 13 Dec 2012
# An asyncronous job for transcoding video files using FFMpeg

class TranscodeVideoJob < ActiveFedoraPidBasedJob
  def queue_name
    :video
  end

  def run
    generic_file.create_derivatives
    generic_file.save
  end
end

