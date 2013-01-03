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
      if can? :read, params["id"]
        logger.info "Can read #{params['id']}"

        send_content (params["id"])
        return
      else 
        logger.info "Can not read #{params['id']}"
        redirect_to "/assets/NoAccess.png"
      end
    end

    protected
    
    def send_content (id)
        @asset = ActiveFedora::Base.find(id)
        opts = {}
        ds = nil
        opts[:filename] = params["filename"] || @asset.label
        opts[:disposition] = 'inline' 
        if params.has_key?(:datastream_id)
          opts[:filename] = params[:datastream_id]
          ds = @asset.datastreams[params[:datastream_id]]
        end
        ds = default_content_ds(@asset) if ds.nil?
        raise ActionController::RoutingError.new('Not Found') if ds.nil?
        data = ds.content
        opts[:type] = ds.mimeType
        send_data data, opts
        return
    end
    
    
    private 
    
    def default_content_ds(asset)
      ActiveFedora::ContentModel.known_models_for(asset).each do |model_class|
        return model_class.default_content_ds if model_class.respond_to?(:default_content_ds)
      end
      if asset.datastreams.keys.include?(DownloadsController.default_content_dsid)
        return asset.datastreams[DownloadsController.default_content_dsid]
      end
    end
    
    module ClassMethods
      def default_content_dsid
        "content"
      end
    end
  end
end
