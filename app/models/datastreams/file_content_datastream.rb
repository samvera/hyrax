require 'open3'
class FileContentDatastream < ActiveFedora::Datastream
  include Open3

  def extract_metadata
    return if content.nil?
    f = Tempfile.new("#{pid}-#{dsVersionID}")
    f.binmode
    if content.respond_to? :read
      f.write(content.read)
    else
      f.write(content)
    end
    f.close
    content.rewind if content.respond_to? :rewind
    command = "#{fits_path} -i #{f.path}"
    stdin, stdout, stderr = popen3(command)
    stdin.close
    out = stdout.read
    stdout.close
    err = stderr.read
    stderr.close
    raise "Unable to execute command \"#{command}\"\n#{err}" unless err.empty? or err.include? "Error parsing Exiftool XML Output"
    f.unlink
    out
  end

  def fits_path
    ScholarSphere::Application.config.fits_path
  end
end
