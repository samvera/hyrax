require 'sufia/single_use_error'

class SingleUseLinksController < DownloadsController
  before_filter :authenticate_user!
  before_filter :find_file
  before_filter :authorize_user!
  skip_filter :normalize_identifier, :load_asset, :load_datastream
  prepend_before_filter :normalize_identifier

  def new_download
    @su = SingleUseLink.create :itemId => params[:id], :path => sufia.download_path(:id => @object)
    @link = sufia.download_single_use_link_path(@su.downloadKey)

    respond_to do |format|
      format.html
      format.js  { render :js => @link }
    end
  end

  def new_show
    @su = SingleUseLink.create :itemId => params[:id], :path => sufia.polymorphic_path(@object)
    @link = sufia.show_single_use_link_path(@su.downloadKey)

    respond_to do |format|
      format.html
      format.js  { render :js => @link }
    end
  end

  protected
  def authorize_user!
    authorize! :read, @object
  end

  def find_file
    @object = ActiveFedora::Base.load_instance_from_solr(params[:id])
  end

end
