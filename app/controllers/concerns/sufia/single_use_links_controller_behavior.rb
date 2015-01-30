module Sufia
  module SingleUseLinksControllerBehavior
    extend ActiveSupport::Concern
    included do

      before_filter :authenticate_user!
      before_filter :authorize_user!
      # Catch permission errors
      rescue_from Hydra::AccessDenied, CanCan::AccessDenied do |exception|
        if current_user and current_user.persisted?
          redirect_to root_url, alert: "You do not have sufficient privileges to create links to this document"
        else
          session["user_return_to"] = request.url
          redirect_to new_user_session_url, alert: exception.message
        end
      end

    end

    def new_download
      @su = SingleUseLink.create itemId: params[:id], path: sufia.download_path(id: asset)
      @link = sufia.download_single_use_link_path(@su.downloadKey)

      respond_to do |format|
        format.html
        format.js  { render js: @link }
      end
    end

    def new_show
      @su = SingleUseLink.create itemId: params[:id], path: sufia.polymorphic_path(asset)
      @link = sufia.show_single_use_link_path(@su.downloadKey)

      respond_to do |format|
        format.html
        format.js  { render js: @link }
      end
    end


    protected
    def authorize_user!
      authorize! :edit, asset
    end

    def asset
      @asset ||= ActiveFedora::Base.load_instance_from_solr(params[:id])
    end

  end
end
