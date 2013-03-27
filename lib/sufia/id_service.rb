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

require 'noid'

module Sufia
  class IdService
    @@minter = ::Noid::Minter.new(:template => '.reeddeeddk')
    @@namespace = Sufia::Engine.config.id_namespace
    def self.valid?(identifier)
      # remove the fedora namespace since it's not part of the noid
      noid = identifier.split(":").last
      return @@minter.valid? noid
    end
    def self.mint
      while true
        pid = self.next_id
        break unless ActiveFedora::Base.exists?(pid)
      end
      return pid
    end

    protected

    def self.next_id
      pid = ''
      File.open("tmp/minter-state", File::RDWR|File::CREAT, 0644) {|f|
        f.flock(File::LOCK_EX)
        yaml = YAML::load(f.read)
        yaml = {:template => '.reeddeeddk'} unless yaml
        minter = ::Noid::Minter.new(yaml)
        pid =  "#{@@namespace}:#{minter.mint}"
        f.rewind
        yaml = YAML::dump(minter.dump)
        f.write yaml
        f.flush
        f.truncate(f.pos)
      }
      return pid
    end
    
  end
end
