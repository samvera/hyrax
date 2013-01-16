class SingleUseLinkController < DownloadsController
  before_filter :authenticate_user!, :except => [:show, :download]
  skip_filter :normalize_identifier
  prepend_before_filter :normalize_identifier, :except => [:download, :show]
  
  def generate_download
    @generic_file = GenericFile.find(params[:id])
    authorize! :read, @generic_file   
    @su =  SingleUseLink.create_download(params[:id])
    @link =  sufia.download_single_use_link_path(@su.downloadKey)
    respond_to do |format|
      format.html
      format.js  {render :js => @link}
    end
    
  end

  def generate_show
    @generic_file = GenericFile.find(params[:id])
    authorize! :read, @generic_file   
    @su = SingleUseLink.create_show(params[:id])
    @link = sufia.show_single_use_link_path(@su.downloadKey)
    respond_to do |format|
      format.html
      format.js  {render :js => @link}
    end
    
  end

  def download
    #look up the item
    link = lookup_hash

    #grab the item id
    id = link.itemId 
    
    #check to make sure the path matches
    not_found if link.path != sufia.download_path(id)
    
    # send the data content
    asset = ActiveFedora::Base.find(id, :cast=>true)
    send_content(asset)
  end

  def show
    link = lookup_hash

    #grab the item id
    id = link.itemId 
    
    #check to make sure the path matches
    not_found if link.path != sufia.generic_file_path(id)
    
    #show the file
    @generic_file = GenericFile.find(id)
    @terms = @generic_file.terms_for_display
    
    # create a dowload link that is single use for the user since we do not just want to show metadata we want to access it too
    @su =  SingleUseLink.create_download(id)
    @download_link =  sufia.download_single_use_link_path(@su.downloadKey)
  end
  
  protected
  
  def lookup_hash  
    id = params[:id]
    # invalid hash send not found
    link = SingleUseLink.find_by_downloadKey(id) ||  not_found
     
    # expired hash send not found
    now = DateTime.now
    not_found if link.expires <= now 
        
    # delete the link since it has been used
    link.destroy
    
    return link
  end
  
  def not_found 
    raise ActionController::RoutingError.new('Not Found') 
  end 
  def expired 
    raise ActionController::RoutingError.new('expired') 
  end 
end
