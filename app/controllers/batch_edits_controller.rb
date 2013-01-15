class BatchEditsController < ApplicationController  
   include Hydra::BatchEditBehavior
   include GenericFileHelper
   
   def edit
       super 
       @generic_file = GenericFile.new
       @generic_file.depositor = current_user.user_key
       @groups = current_user.groups       
       @terms = @generic_file.get_terms.reject{|k,v| (k=='generic_file__title')|| (k == 'generic_file__part_of')|| (k == 'generic_file__date_uploaded') || (k == 'generic_file__date_modified')}

       # do we want to show the original values for anything...
       @show_file = GenericFile.new
       @show_file.depositor = current_user.user_key
       h  = {}
       @names = []
       permissions = []
       batch.each do |doc_id|
          gf = GenericFile.find(doc_id)
          h = h.merge(gf.get_values) {|key, v1, v2| (v1+v2).uniq }
          @names << display_title(gf)    
          permissions =  (permissions+gf.permissions).uniq
       end
       
       # why am I doing this you may ask... Well... if truth be told I have no idea, but if I use just a single item in the batch
       # my h arrays get converted into strings in update attributes unless I do this first....
       h.keys.each {|key| h[key] = h[key].to_a} if (batch.size == 1)        
       # end of wierd fix...
       
       @show_file.update_attributes(h)
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
