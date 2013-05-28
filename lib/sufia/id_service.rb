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
  module IdService

    def self.noid_template
      Sufia.config.noid_template
    end

    @minter = ::Noid::Minter.new(:template => noid_template)
    @pid = $$
    @namespace = Sufia::Engine.config.id_namespace
    @semaphore = Mutex.new
    def self.valid?(identifier)
      # remove the fedora namespace since it's not part of the noid
      noid = identifier.split(":").last
      return @minter.valid? noid
    end
    def self.mint
      @semaphore.synchronize do
        while true
          pid = self.next_id
          return pid unless ActiveFedora::Base.exists?(pid)
        end
      end
    end

    protected

    def self.next_id
      pid = ''
      File.open(Sufia::Engine.config.minter_statefile, File::RDWR|File::CREAT, 0644) do |f|
        f.flock(File::LOCK_EX)
        yaml = YAML::load(f.read)
        yaml = {:template => noid_template} unless yaml
        minter = ::Noid::Minter.new(yaml)
        pid = "#{@namespace}:#{minter.mint}"
        f.rewind
        yaml = YAML::dump(minter.dump)
        f.write yaml
        f.flush
        f.truncate(f.pos)
      end
      return pid
    end
  end
end
