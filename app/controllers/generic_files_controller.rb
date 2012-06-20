class GenericFilesController < ApplicationController
  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::FileAssetsHelper
  include PSU::Noid

  # actions: audit, index, create, new, edit, show, update, destroy
  before_filter :authenticate_user!, :only=>[:create, :new]
  before_filter :enforce_access_controls, :only=>[:edit, :update, :show, :audit, :index, :destroy, :permissions]
  before_filter :find_by_id, :only=>[:audit, :edit, :show, :update, :destroy, :permissions]
  prepend_before_filter :normalize_identifier, :only=>[:audit, :edit, :show, :update, :destroy, :permissions] 
  
  # routed to /files/new
  def new
    @generic_file = GenericFile.new 
    @batch_noid = PSU::Noid.noidify(PSU::IdService.mint)
    @dc_metadata = [
      ['Based Near', 'based_near'],
      ['Contributor', 'contributor'],
      ['Creator', 'creator'], 
      ['Date Created', 'date_created'], 
      ['Description', 'description'],
      ['Identifier', 'identifier'],
      ['Language', 'language'], 
      ['Publisher', 'publisher'], 
      ['Rights', 'rights'],
      ['Subject', 'subject'], 
      ['Tag', 'tag'], 
      ['Title', 'title'],
      ['Related URL', 'related_url']
    ]
  end

  # routed to /files/:id/edit
  def edit
    @terms = @generic_file.get_terms
  end

  # routed to /files/:id
  def index
    @generic_files = GenericFile.find(:all, :rows => GenericFile.count)
    render :json => @generic_files.collect { |p| p.to_jq_upload }.to_json
  end

  # routed to /files/:id (DELETE)
  def destroy
    @generic_file.delete
    redirect_to dashboard_path, :notice => render_to_string(:partial=>'generic_files/asset_deleted_flash', :locals => { :generic_file => @generic_file })
  end

  # routed to /files (POST)
  def create
    retval = " "
    # check error condition No files
    if !params.has_key?(:files)
       retval = render :json => [{:error => "Error! No file to save"}].to_json
    
    # check error condition empty file
    elsif ((params[:files][0].respond_to?(:tempfile)) && (params[:files][0].tempfile.size == 0))
       retval = render :json => [{ :name => params[:files][0].original_filename, :error => "Error! Zero Length File!"}].to_json

    elsif ((params[:files][0].respond_to?(:size)) && (params[:files][0].size == 0))
       retval = render :json => [{ :name => params[:files][0].original_filename, :error => "Error! Zero Length File!"}].to_json
    
    elsif (params[:terms_of_service] != '1')
       retval = render :json => [{ :name => params[:files][0].original_filename, :error => "You must accept the terms of service!"}].to_json
    
    # process file
    else
      create_and_save_generic_file 
      if @generic_file
        respond_to do |format|
          format.html {
            retval = render :json => [@generic_file.to_jq_upload].to_json,
              :content_type => 'text/html',
              :layout => false
          }
          format.json {
            retval = render :json => [@generic_file.to_jq_upload].to_json
          }
        end
      else
        puts "respond bad"
        retval = render :json => [{:error => "Error creating generic file."}].to_json
      end
    end
    
    return retval
  end

  # routed to /files/:id
  def show
  end

  # routed to /files/:id/audit (POST)
  def audit
    render :json=>@generic_file.audit
  end
 
  # routed to /files/:id (PUT)
  def update
    if params.has_key?(:revision) and params[:revision] !=  @generic_file.content.latest_version.versionID
      revision = @generic_file.content.get_version(params[:revision])
      @generic_file.add_file_datastream(revision.content, :dsid => 'content')
    end
    add_posted_blob_to_asset(@generic_file, params[:filedata]) if params.has_key?(:filedata) 
    @generic_file.update_attributes(params[:generic_file].reject { |k,v| %w{ Filedata Filename revision part_of date_modified date_uploaded format }.include? k})
    @generic_file.date_modified = Time.now.ctime
    @generic_file.save
    redirect_to dashboard_path, :notice => render_to_string(:partial=>'generic_files/asset_updated_flash', :locals => { :generic_file => @generic_file })
  end

  # routed to /files/:id/permissions (POST)
  def permissions
    Scholarsphere::GenericFile::Permissions.parse_permissions(params)
    @generic_file.update_attributes(params[:generic_file].reject { |k,v| %w{ Filedata Filename revision}.include? k})
    @generic_file.save
    redirect_to edit_generic_file_path, :notice => render_to_string(:partial=>'generic_files/asset_updated_flash', :locals => { :generic_file => @generic_file })
  end

  protected
  def find_by_id
    @generic_file = GenericFile.find(params[:id])
  end

  def create_and_save_generic_file      
    unless params.has_key?(:files)
      logger.warn "!!!! No Files !!!!"
      return
    end
    @generic_file = GenericFile.new    
    @generic_file.terms_of_service = params[:terms_of_service]
    file = params[:files][0]

    # if we want to be able to save zero length files then we can use this to make the file 1 byte instead of zero length and fedora will take it
    #if (file.tempfile.size == 0)
    #   logger.warn "Encountered an empty file...  Creating a new temp file with on space."
    #   f = Tempfile.new ("emptyfile")
    #   f.write " "
    #   f.rewind
    #   file.tempfile = f
    #end
    add_posted_blob_to_asset(@generic_file,file)
    apply_depositor_metadata(@generic_file)
    @generic_file.date_uploaded = Time.now.ctime
    @generic_file.date_modified = Time.now.ctime
    @generic_file.relative_path = params[:relative_path] if params.has_key?(:relative_path)

    if params.has_key?(:batch_id)
      batch_id = PSU::Noid.namespaceize(params[:batch_id])
      @generic_file.add_relationship("isPartOf", "info:fedora/#{batch_id}")
    else
      logger.warn "unable to find batch to attach to"
    end
    @generic_file.save      
    Delayed::Job.enqueue(UnzipJob.new(@generic_file.pid)) if file.content_type == 'application/zip'
    return @generic_file
  end
end
