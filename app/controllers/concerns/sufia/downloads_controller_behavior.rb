module Sufia
  module DownloadsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::Controller::DownloadBehavior

    def datastream_name
      if !params[:datastream_id] || params[:datastream_id] == self.class.default_content_dsid
        params[:filename] || asset.label
      else
        params[:datastream_id]
      end
    end
  end
end
