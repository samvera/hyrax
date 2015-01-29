module Sufia
  module DownloadsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::Controller::DownloadBehavior

    def file_name
      if !params[:file] || params[:file] == self.class.default_file_path
        params[:filename] || asset.label
      else
        params[:file]
      end
    end
  end
end
