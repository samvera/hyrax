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

    included do
      # module mixes in normalize_identifier method
      include Sufia::Noid

      # moved check into the routine so we can handle the user with no access 
      prepend_before_filter :normalize_identifier 
    end
    
    def show
      if can? :read, params[:id]
        asset = ActiveFedora::Base.load_instance_from_solr(params[:id])
        # we can now examine @asset and determine if we should send_content, or some other action.
        send_content (asset)
      else 
        logger.info "Can not read #{params[:id]}"
        raise Hydra::AccessDenied.new("You do not have sufficient access privileges to read this document, which has been marked private.", :read, params[:id])
      end
    end

    protected

    def datastream_name
      @datastream_name ||= params[:datastream_id] || DownloadsController.default_content_dsid
    end

    def send_content(asset)
        opts = {disposition: 'inline'}
        if default_datastream?
          opts[:filename] = params["filename"] || asset.label
        else
          opts[:filename] = params[:datastream_id]
        end
        ds = asset.datastreams[datastream_name]
        raise ActionController::RoutingError.new('Not Found') if ds.nil?
        data = ds.content
        opts[:type] = ds.mimeType
        send_data data, opts
    end
    
    def default_datastream?
      datastream_name == self.class.default_content_dsid
    end
    
    private 
    
    module ClassMethods
      def default_content_dsid
        "content"
      end
    end
  end
end
