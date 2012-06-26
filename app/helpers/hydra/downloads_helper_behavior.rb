require 'deprecation'

module Hydra
  module DownloadsHelperBehavior
    extend Deprecation
    
    self.deprecation_horizon = 'hydra-head 5.x'
    
    def list_downloadables( datastreams, mime_types=["application/pdf"])
      result = "<ul>" 
             
      datastreams.each_value do |ds|
        result << "<li>"
        result << link_to(ds.label, hydra_asset_downloads_path(ds.pid, :download_id=>ds.dsid))
        result << "</li>"     
      end
          
      result << "</ul>"
      return result
    end
    deprecation_deprecate :list_downloadables
    
  end
end
