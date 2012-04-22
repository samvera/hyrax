class BatchController < ApplicationController
  
  include Hydra::Controller
  include Hydra::AssetsControllerHelper  # This is to get apply_depositor_metadata method
  include Hydra::FileAssetsHelper

  #before_filter :enforce_access_controls, :only=>[:edit, :update]
  
  def edit
    @batch = Batch.find(params[:id])
    @generic_file = GenericFile.new 
  end


  def update
    #render :edit 
    @batch = Batch.find(params[:id])
    puts "params"
    pp params
    puts "batch"
    pp @batch
    @generic_files = []
    puts "params generic file"
    pp params[:generic_file]
    @batch.part.each do |gf_pid|
      gf = GenericFile.find(gf_pid)
      puts "gf"
      pp gf
      if params.has_key?(:permission)
        gf.datastreams["rightsMetadata"].permissions({:group=>"public"}, params[:permission][:group][:public])
      else
        gf.datastreams["rightsMetadata"].permissions({:group=>"public"}, "none")
      end

      gf.based_near = params[:generic_file][:based_near] if params[:generic_file].has_key?(:based_near) 
      gf.contributor = params[:generic_file][:contributor] if params[:generic_file].has_key?(:contributor)
      gf.creator = params[:generic_file][:creator] if params[:generic_file].has_key?(:creator)
      gf.date_created = params[:generic_file][:date_created] if params[:generic_file].has_key?(:date_created)
      gf.description = params[:generic_file][:description] if params[:generic_file].has_key?(:description)
      gf.identifier = params[:generic_file][:identifier] if params[:generic_file].has_key?(:identifier)
      gf.language = params[:generic_file][:language] if params[:generic_file].has_key?(:language)
      gf.publisher = params[:generic_file][:publisher] if params[:generic_file].has_key?(:publisher)
      gf.rights = params[:generic_file][:rights] if params[:generic_file].has_key?(:rights)
      gf.subject = params[:generic_file][:subject] if params[:generic_file].has_key?(:subject)
      gf.tag = params[:generic_file][:tag] if params[:generic_file].has_key?(:tag)
      gf.title = params[:generic_file][:title] if params[:generic_file].has_key?(:title) 
      gf.save
      #gf.delay.save
      @generic_files << gf
    end
    notice = []
    puts "flashing"
    @generic_files.each do |gf|
      notice << render_to_string(:partial=>'generic_files/asset_saved_flash', :locals => { :generic_file => gf })
      puts "noticing"
    end
    puts "ready to redirect"
    flash[:notice] = notice.join("<br/>".html_safe) unless notice.blank?
    redirect_params = {:controller => "dashboard", :action => "index"} 
    redirect_to redirect_params
  end

end
