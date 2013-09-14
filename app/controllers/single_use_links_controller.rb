require 'sufia/single_use_error'

class SingleUseLinksController < ApplicationController
  include Sufia::Noid

  prepend_before_filter :normalize_identifier
  before_filter :load_asset
  before_filter :authenticate_user!
  before_filter :authorize_user!

  def new_download
    @su = SingleUseLink.create :itemId => params[:id], :path => sufia.download_path(:id => @asset)
    @link = sufia.download_single_use_link_path(@su.downloadKey)

    respond_to do |format|
      format.html
      format.js  { render :js => @link }
    end
  end

  def new_show
    @su = SingleUseLink.create :itemId => params[:id], :path => sufia.polymorphic_path(@asset)
    @link = sufia.show_single_use_link_path(@su.downloadKey)

    respond_to do |format|
      format.html
      format.js  { render :js => @link }
    end
  end

  protected
  def authorize_user!
    authorize! :read, @asset
  end

  def load_asset
    @asset = ActiveFedora::Base.load_instance_from_solr(params[:id])
  end

end
