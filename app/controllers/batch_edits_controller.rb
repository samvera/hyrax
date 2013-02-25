class BatchEditsController < ApplicationController  
   include Hydra::BatchEditBehavior
   include GenericFileHelper
   
   def edit
       super 
       @generic_file = GenericFile.new
       @generic_file.depositor = current_user.user_key
       @terms = @generic_file.terms_for_editing - [:title] # +:format, :resource_type 

       # do we want to show the original values for anything...
       @show_file = GenericFile.new
       @show_file.depositor = current_user.user_key
       h  = {}
       @names = []
       permissions = []

       # For each of the files in the batch, set the attributes to be the concatination of all the attributes
       batch.each do |doc_id|
          gf = GenericFile.find(doc_id)
          gf.terms_for_editing.each do |key|
            h[key] ||= []
            h[key] = (h[key] + gf.send(key)).uniq 
          end
          @names << display_title(gf)    
          permissions =  (permissions+gf.permissions).uniq
       end

       @show_file.terms_for_editing.each do |key|
         # if value is empty, we create an one element array to loop over for output 
         h[key] = [''] if h[key].empty?
       end
       
       @show_file.attributes = h
       # map the permissions to parameter like input so that the assign will work
       # todo sort the access level some how...
       perm_param ={'user'=>{},'group'=>{"public"=>"1"}}
       permissions.each{ |perm| perm_param[perm[:type]][perm[:name]] = perm[:access]}
       @show_file.permissions = HashWithIndifferentAccess.new(perm_param)       
   end

   def after_update 
     redirect_to sufia.dashboard_index_path unless request.xhr?
   end
   
  def update_document(obj)
      super
      obj.date_modified = Time.now.ctime
      obj.set_visibility(params[:visibility])
  end
    
   def update
      # keep the batch around if we are doing ajax calls
      batch_sav = batch.dup if request.xhr?        
      catalog_index_path = sufia.dashboard_index_path
      type = params["update_type"]
      if (type == "update")
        #params["generic_file"].reject! {|k,v| (v.blank? || (v.respond_to?(:length) && v.length==1 && v.first.blank?))}
        super        
      elsif (type == "delete_all")
        batch.each do |doc_id|
          gf = GenericFile.find(doc_id)
          gf.delete
        end
        clear_batch! 
        after_update
      end

      # reset the batch around if we are doing ajax calls
      if request.xhr?
        self.batch = batch_sav.dup 
        @key = params["key"]
        if (@key != "permissions")
            @vals = params["generic_file"][@key]
        else
            @vals = [""]
        end            
        render :update_edit
      end        
   end
end   
