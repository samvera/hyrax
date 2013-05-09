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

module Sufia
  module DownloadsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::Controller::DownloadBehavior

    included do
      # module mixes in normalize_identifier method
      include Sufia::Noid

      # moved check into the routine so we can handle the user with no access 
      prepend_before_filter :normalize_identifier 
    end
    
    def datastream_name
      if datastream.dsid == self.class.default_content_dsid
        params[:filename] || asset.label
      else
        params[:datastream_id]
      end
    end

  end
end
