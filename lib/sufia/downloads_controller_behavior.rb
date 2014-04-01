module Sufia
  module DownloadsControllerBehavior
    extend ActiveSupport::Concern
    include Hydra::Controller::DownloadBehavior

    included do
      # module mixes in normalize_identifier method
      include Sufia::Noid

      # moved check into the routine so we can handle the user with no access
      prepend_before_filter :normalize_identifier

      # Catch permission errors
      # todo: Remove this once Hydra Head 7.0.1 comes out since this should be fixed
      #       in hydra-head
      rescue_from CanCan::AccessDenied do |exception|
        if current_user and current_user.persisted?
          redirect_to root_url, :alert => exception.message
        else
          redirect_to new_user_session_url, :alert => exception.message
        end
      end
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
