module Hydra
  module DownloadsHelperBehavior
    
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
    
  end
end
