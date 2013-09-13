require 'sufia/single_use_error'

class SingleUseLinkController < DownloadsController
  before_filter :authenticate_user!, :except => [:download, :show]
  before_filter :find_file, :only => [:generate_download, :generate_show]
  before_filter :authorize_user!, :only => [:generate_download, :generate_show]
  skip_filter :normalize_identifier, :load_asset, :load_datastream
  prepend_before_filter :normalize_identifier, :except => [:download, :show]
  rescue_from Sufia::SingleUseError, :with => :render_single_use_error
  rescue_from ActiveRecord::RecordNotFound, :with => :render_single_use_error

  before_filter :load_link, :except => [:generate_download, :generate_show]

  def generate_download
    @su = SingleUseLink.create :itemId => params[:id], :path => sufia.download_path(:id => @object)
    @link = sufia.download_single_use_link_path(@su.downloadKey)

    respond_to do |format|
      format.html
      format.js  { render :js => @link }
    end
  end

  def generate_show
    @su = SingleUseLink.create :itemId => params[:id], :path => sufia.polymorphic_path(@object)
    @link = sufia.show_single_use_link_path(@su.downloadKey)

    respond_to do |format|
      format.html
      format.js  { render :js => @link }
    end
  end

  def download
    #grab the item id
    id = @link.itemId
    @asset = ActiveFedora::Base.load_instance_from_solr(id)

    #check to make sure the path matches
    raise not_found_exception unless @link.path == sufia.download_path(:id => @asset)

    # send the data content
    load_datastream
    send_content(asset)
  end

  def show
    #grab the item id
    id = @link.itemId
    @object = ActiveFedora::Base.load_instance_from_solr(id)
    #check to make sure the path matches
    raise not_found_exception unless @link.path == sufia.polymorphic_path(@object)

    #show the file
    @terms = @object.terms_for_display

    # create a dowload link that is single use for the user since we do not just want to show metadata we want to access it too
    @su = @link.create_for_path sufia.download_path(:id => @object)
    @download_link = sufia.download_single_use_link_path(@su.downloadKey)
  end

  protected
  def authorize_user!
    authorize! :read, @object
  end

  def find_file
    @object = ActiveFedora::Base.load_instance_from_solr(params[:id])
  end

  def load_link
    # invalid hash send not found
    @link = SingleUseLink.find_by_downloadKey! params[:id]

    # expired hash send not found
    raise expired_exception if @link.expired?

    # delete the link since it has been used
    @link.destroy

    return @link
  end

  def not_found_exception
    Sufia::SingleUseError.new('Single-Use Link Not Found')
  end

  def expired_exception
    Sufia::SingleUseError.new('Single-Use Link Expired')
  end
end
