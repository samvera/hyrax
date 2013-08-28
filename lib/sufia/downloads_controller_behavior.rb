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
