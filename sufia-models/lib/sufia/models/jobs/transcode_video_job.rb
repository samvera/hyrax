# Created by: Justin Coyne
# 13 Dec 2012
# An asyncronous job for transcoding video files using FFMpeg

class TranscodeVideoJob
  def queue_name
    :video
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

