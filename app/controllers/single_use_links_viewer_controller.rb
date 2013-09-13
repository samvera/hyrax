require 'sufia/single_use_error'

class SingleUseLinksViewerController < DownloadsController
  skip_filter :normalize_identifier, :load_asset, :load_datastream
  before_filter :load_link

  rescue_from Sufia::SingleUseError, :with => :render_single_use_error
  rescue_from ActiveRecord::RecordNotFound, :with => :render_single_use_error


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
