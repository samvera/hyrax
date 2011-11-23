require 'mediashelf/active_fedora_helper'
class GetController < ApplicationController
    include MediaShelf::ActiveFedoraHelper
    include Hydra::RepositoryController
    include Hydra::AssetsControllerHelper
    helper :downloads
    
    def show
      fedora_object = ActiveFedora::Base.load_instance(params[:id])
      
      respond_to do |format|
        format.html { send_datastream downloadables( fedora_object, :canonical=>true ) }
        format.pdf { send_datastream downloadables( fedora_object, :canonical=>true, :mime_type=>"application/pdf" ) }
        format.jp2 do 
          canonical_jp2 = downloadables( fedora_object, :canonical=>true, :mime_type=>"image/jp2" )
          jp2_content_url = "#{canonical_jp2.url}/content"
          send_datastream canonical_jp2
        end
      end
      
    end
    
end
