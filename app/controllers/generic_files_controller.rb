class GenericFilesController < ApplicationController
  
  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::FileAssetsHelper

  # actions: audit, index, create, new, edit, show, update, destroy
  before_filter :authenticate_user!, :only=>[:create, :new]
  before_filter :enforce_access_controls, :only=>[:edit, :update, :show, :audit, :index, :destroy]
  prepend_before_filter :normalize_identifier, :only=>[:audit, :edit, :show, :update, :destroy] 

  # routed to /files/new
  def new
    @generic_file = GenericFile.new 
    @batch = Batch.new
    @batch.save
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
    ]
  end

  # routed to /files/:id/edit
  def edit
    @generic_file = GenericFile.find(params[:id])
  end


  def index
    @generic_files = GenericFile.find(:all, :count=>GenericFile.count)
    render :json => @generic_files.collect { |p| p.to_jq_upload }.to_json
  end


  # routed to /files (POST)
  def create
    create_and_save_generic_file 
    if @generic_file
      respond_to do |format|
        format.html {
          render :json => [@generic_file.to_jq_upload].to_json,
            :content_type => 'text/html',
            :layout => false
        }
        format.json {
          render :json => [@generic_file.to_jq_upload].to_json
        }
      end
    else
      puts "respond bad"
      render :json => [{:error => "custom_failure"}], :status => 304
    end
  end
 
  def create_delayed_job
    params[:generic_file] = {} unless params.has_key? :generic_file
    
    # check the meta data first before trying to create files
    # No need to go through the create if the descriptives are not right...
    if params[:generic_file].has_key? :creator and params[:generic_file][:creator].empty?
      flash[:notice] = "You must include a creator."
      redirect_params = {:controller => "generic_files", :action => "new"} 
      
    # valid descriptions create the file objects
    else 
      create_and_save_generic_files_from_params
  
      #verify that files have been uploaded otherwise that needs to change
      if @generic_files.empty? 
        flash[:notice] = "You must specify a file to upload" 
        redirect_params = {:controller => "generic_files", :action => "new"} 
      
      # no errors occured!
      else
        notice = []
        @generic_files.each do |gf|
          notice << render_to_string(:partial=>'generic_files/asset_saved_flash', :locals => { :generic_file => gf })
        end
        flash[:notice] = notice.join("<br/>".html_safe) unless notice.blank?
        redirect_params = {:controller => "dashboard", :action => "index"} 
      end
    end
    logger.info redirect_params.inspect
    redirect_to redirect_params 
  end

  # routed to /files/:id
  def show
    @generic_file = GenericFile.find(params[:id])
  end

  # routed to /files/:id/audit (POST)
  def audit
    @generic_file = GenericFile.find(params[:id])
    render :json=>@generic_file.audit
  end
 
  # routed to /files/:id (PUT)
  def update
    @generic_file = GenericFile.find(params[:id])
    @generic_file.update_attributes(params[:generic_file].reject { |k,v| k=="Filedata" || k=="Filename"})
    @generic_file.date_modified = [Time.now.ctime]

    #added to cause solr to re-index facets
    @generic_file.update_index
    
    flash[:notice] = "Successfully updated." 
    add_posted_blob_to_asset(generic_file, params[:Filedata]) if params.has_key?(:Filedata) 
    render :edit 
  end

  def delayed_create(generic_file, params, file)
    create_and_save_generic_files_from_params_delayed(generic_file, params, file)
  end
  

  protected
  def normalize_identifier
    params[:id] = "#{ScholarSphere::Application.config.id_namespace}:#{params[:id]}" unless params[:id].start_with? ScholarSphere::Application.config.id_namespace
  end

  def create_and_save_generic_file
      
    if params.has_key?(:files)
      @generic_file = GenericFile.new
      file = params[:files][0]
      add_posted_blob_to_asset(@generic_file,file)
      apply_depositor_metadata(@generic_file)
      # Delete this next line when GenericFile.label no longer wipes out the title
      @generic_file.label = file.original_filename
      @generic_file.date_uploaded  << Time.now.ctime
      @generic_file.date_modified  << Time.now.ctime
      @generic_file.save
      if params.has_key?(:batch_id)
        @batch = Batch.find(params[:batch_id])
        @batch.part << @generic_file.pid
        @batch.save
      else
        puts "unable to find batch to attach to"
      end
      @generic_file
    else
      @generic_file
    end
  end


  # takes form file inputs and assigns meta data individually 
  # to each generic file asset and saves generic file assets # @param [Hash] of form fields
  def create_and_save_generic_files_from_params
    @generic_files = []
    if params.has_key?(:Filedata)
      params[:Filedata].each do |file|
        #Look up parameters
        params[:generic_file] = {} unless params.has_key? :generic_file
        generic_file = GenericFile.new(params[:generic_file].reject {|k,v| k=="Filedata" || k=="Filename"})
 
        apply_depositor_metadata(generic_file)
        
        if params.has_key?(:permission)
          generic_file.datastreams["rightsMetadata"].permissions({:group=>"public"}, params[:permission][:group][:public])
        else
          generic_file.datastreams["rightsMetadata"].permissions({:group=>"public"}, "none")
        end
        generic_file.date_uploaded  << Time.now.ctime
        generic_file.date_modified  << Time.now.ctime


        # call save on what we have store so far and then delay the rest
        # need to have script/delayed_job start running to have these picked up
        generic_file.save
        Delayed::Job.enqueue GenericFileSaveJob.new(generic_file.id, params,  file)
        logger.info "Delaying Job"

        #no delay call the method right away
        #create_and_save_generic_files_from_params_delayed(generic_file, params, file)

        @generic_files << generic_file
      end
    end
    @generic_files
  end

  def create_and_save_generic_files_from_params_delayed(generic_file, params, file)
     logger.info "*****!!!!!**** in Delayed worker now *****!!!!!****"  
     add_posted_blob_to_asset(generic_file,file)
     generic_file.label = file.original_filename

      # Delete this next line when GenericFile.label no longer wipes out the title

      generic_file.based_near = params[:generic_file][:based_near] if params[:generic_file].has_key?(:based_near) 
      generic_file.contributor = params[:generic_file][:contributor] if params[:generic_file].has_key?(:contributor)
      generic_file.creator = params[:generic_file][:creator] if params[:generic_file].has_key?(:creator)
      generic_file.date_created = params[:generic_file][:date_created] if params[:generic_file].has_key?(:date_created)
      generic_file.description = params[:generic_file][:description] if params[:generic_file].has_key?(:description)
      generic_file.identifier = params[:generic_file][:identifier] if params[:generic_file].has_key?(:identifier)
      generic_file.language = params[:generic_file][:language] if params[:generic_file].has_key?(:language)
      generic_file.publisher = params[:generic_file][:publisher] if params[:generic_file].has_key?(:publisher)
      generic_file.rights = params[:generic_file][:rights] if params[:generic_file].has_key?(:rights)
      generic_file.subject = params[:generic_file][:subject] if params[:generic_file].has_key?(:subject)
      generic_file.tag = params[:generic_file][:tag] if params[:generic_file].has_key?(:tag)
      generic_file.title = params[:generic_file][:title] if params[:generic_file].has_key?(:title) 


      generic_file.save
      #generic_file.delay.save
  end


end
