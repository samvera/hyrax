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

class ResolrizeJob
  def queue_name
    :resolrize
  end

  def run
    require 'active_fedora/version'
    active_fedora_version = Gem::Version.new(ActiveFedora::VERSION)
    minimum_feature_version = Gem::Version.new('6.4.4')
    if active_fedora_version >= minimum_feature_version
      ActiveFedora::Base.reindex_everything("pid~#{Sufia.config.id_namespace}:*")
    else
      ActiveFedora::Base.reindex_everything
    end
  end
end
