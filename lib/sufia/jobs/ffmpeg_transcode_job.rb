# Created by: Justin Coyne
# 7 Feb 2013
# An abstract class for asyncronous jobs that transcode files using FFMpeg

require 'tmpdir'

class FfmpegTranscodeJob
  extend Open3

  attr_accessor :generic_file_id, :datastream_in, :datastream, :generic_file

  def initialize(generic_file_id, datastream_in)
    self.generic_file_id = generic_file_id
    self.datastream_in = datastream_in
  end

  def process
    raise "You attempted to call process() on an abstract class.  Implement process() on the concrete class"
  end

  def run
    return unless Sufia::Engine.config.enable_ffmpeg
    self.generic_file = GenericFile.find(generic_file_id)
    self.datastream = generic_file.datastreams[datastream_in]
    if datastream
      process 
      generic_file.save!
    else
      logger.warn "No datastream for transcoding!!!!! pid: #{generic_file_id} dsid: #{datastream_in}"
    end
  end

  def encode_datastream(dest_dsid, mime_type, options)
    file_suffix = dest_dsid
    out_file = nil
    output_file = Dir::Tmpname.create(['sufia', ".#{file_suffix}"], Sufia::Engine.config.temp_file_base){}
    datastream.to_tempfile do |f|
      self.class.encode(f.path, options, output_file)
    end
    out_file = File.open(output_file, "rb")
    generic_file.add_file_datastream(out_file.read, :dsid=>dest_dsid, :mimeType=>mime_type)
    File.unlink(output_file)
  end

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


