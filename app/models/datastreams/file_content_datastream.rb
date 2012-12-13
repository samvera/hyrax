# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'open3'
class FileContentDatastream < ActiveFedora::Datastream
  include Open3

  def to_tempfile &block
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
    yield(f)
    f.unlink

  end

  def extract_metadata
    out = nil
    to_tempfile do |f|
      command = "#{fits_path} -i #{f.path}"
      stdin, stdout, stderr = popen3(command)
      stdin.close
      out = stdout.read
      stdout.close
      err = stderr.read
      stderr.close
      raise "Unable to execute command \"#{command}\"\n#{err}" unless err.empty? or err.include? "Error parsing Exiftool XML Output"
    end
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
    Sufia::Engine.config.fits_path
  end
end
