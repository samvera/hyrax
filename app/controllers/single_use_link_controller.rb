class SingleUseLinkController < DownloadsController
  before_filter :authenticate_user!, :except => [:show, :download]
  skip_filter :normalize_identifier
  prepend_before_filter :normalize_identifier, :except => [:download, :show]
  
  def generate_download
    id  = check_single_use_link
    @su =  SingleUseLink.create_download(id)
    @link =  Rails.application.routes.url_helpers.download_single_use_link_path(@su.downloadKey)
    @generic_file = GenericFile.find(id)
    respond_to do |format|
      format.html
      format.js  {render :js => @link}
    end
    
  end

  def generate_show
    id  = check_single_use_link
    @su = SingleUseLink.create_show(id)
    @link = Rails.application.routes.url_helpers.show_single_use_link_path(@su.downloadKey)
    @generic_file = GenericFile.find(id)
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
    not_found if link.path != Rails.application.routes.url_helpers.download_path(id)
    
    # send the data content
    send_content(id)
  end

  def show
    link = lookup_hash

    #grab the item id
    id = link.itemId 
    
    #check to make sure the path matches
    not_found if link.path != Rails.application.routes.url_helpers.generic_file_path(id)
    
    #show the file
    @generic_file = GenericFile.find(id)
    @terms = @generic_file.get_terms
    #render 'generic_files/show'
    
    # create a dowload link that is single use for the user since we do not just want to show metadata we want to access it too
    @su =  SingleUseLink.create_download(id)
    @download_link =  Rails.application.routes.url_helpers.download_single_use_link_path(@su.downloadKey)
  end
  
  protected
  
  def check_single_use_link
    id = params[:id]
    # make sure the user is allowed to read the document before they generate the link
    perms = permissions_solr_doc_for_id(id)
    @can_read =  can? :read, perms    
    return id
  end
  
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
