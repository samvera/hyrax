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

  # TODO: All the version functionality here + what's in the GF model should probably move into a mixin
  def get_version(version_id)
    self.versions.select { |v| v.versionID == version_id}.first
  end

  def latest_version
    self.versions.first
  end

  def version_committer(version)
    vc = VersionCommitter.where(:obj_id => version.pid,
                                :datastream_id => version.dsid,
                                :version_id => version.versionID)
    return vc.empty? ? nil : vc.first.committer_login
  end

  def fits_path
    ScholarSphere::Application.config.fits_path
  end
end
