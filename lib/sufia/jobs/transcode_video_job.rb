# Created by: Justin Coyne
# 13 Dec 2012
# An asyncronous job for transcoding video files using FFMpeg

require 'tmpdir'

class TranscodeVideoJob
  extend Open3
  def queue_name
    :video
  end

  attr_accessor :generic_file_id, :datastream_in

  def initialize(generic_file_id, datastream_in)
    self.generic_file_id = generic_file_id
    self.datastream_in = datastream_in
  end

  def run
    @generic_file = GenericFile.find(generic_file_id)
    @datastream = @generic_file.datastreams[datastream_in]
    if @datastream
      encode_mp4()
      encode_webm()
      @generic_file.save!
    else
      logger.warn "No datastream for transcoding!!!!! pid: #{generic_file_id} dsid: #{datastream_in}"
    end
  end

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

  def encode_datastream(dest_dsid, mime_type, options)
    file_suffix = dest_dsid
    out_file = nil
    output_file = Dir::Tmpname.create('sufia'){} + ".#{file_suffix}"
    @datastream.to_tempfile do |f|
      self.class.encode(f.path, options, output_file)
    end
    out_file = File.open(output_file, "rb")
    @generic_file.add_file_datastream(out_file.read, :dsid=>dest_dsid, :mimeType=>mime_type)
    File.unlink(output_file)
  end

  # TODO tmp file for output
  def self.encode(path, options, output_file)
    command = "#{ffmpeg_path} -y -i #{path} #{options} #{output_file}"
    stdin, stdout, stderr, wait_thr = popen3(command)
    stdin.close
    out = stdout.read
    stdout.close
    err = stderr.read
    stderr.close
    raise "Unable to execute command \"#{command}\"\n#{err}" unless wait_thr.value.success?
  end

  def self.ffmpeg_path
    Sufia::Engine.config.ffmpeg_path
  end
end

