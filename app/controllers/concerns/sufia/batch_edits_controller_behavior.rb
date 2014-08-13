module Sufia
  module BatchEditsControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::Breadcrumbs

    included do
      layout "sufia-one-column"
      before_filter :build_breadcrumbs, only: :edit
    end

    def edit
       super
       @generic_file = ::GenericFile.new
       @generic_file.depositor = current_user.user_key
       @terms = @generic_file.terms_for_editing - [:title, :format, :resource_type]

       # do we want to show the original values for anything...
       @show_file = ::GenericFile.new
       @show_file.depositor = current_user.user_key
       h  = {}
       @names = []
       permissions = []

       # For each of the files in the batch, set the attributes to be the concatination of all the attributes
       batch.each do |doc_id|
          gf = ::GenericFile.find(doc_id)
          gf.terms_for_editing.each do |key|
            h[key] ||= []
            h[key] = (h[key] + gf.send(key)).uniq
          end
          @names << gf.to_s
          permissions = (permissions + gf.permissions).uniq
       end

       initialize_fields(h, @show_file)

       # map the permissions to parameter like input so that the assign will work
       # todo sort the access level some how...
       perm_param ={'user'=>{},'group'=>{"public"=>"read"}}
       permissions.each{ |perm| perm_param[perm[:type]][perm[:name]] = perm[:access]}
       @show_file.permissions = HashWithIndifferentAccess.new(perm_param)
    end

    def after_update
      redirect_to_return_controller unless request.xhr?
    end

    def after_destroy_collection
      redirect_to_return_controller unless request.xhr?
    end

    def update_document(obj)
      super
      obj.date_modified = Time.now.ctime
      obj.visibility = params[:visibility]
    end

    def update
      # keep the batch around if we are doing ajax calls
      batch_sav = batch.dup if request.xhr?
      catalog_index_path = sufia.dashboard_index_path
      type = params["update_type"]
      if type == "update"
        super
      elsif type == "delete_all"
        batch.each do |doc_id|
          gf = ::GenericFile.find(doc_id)
          gf.destroy
        end
        after_update
      end

      # reset the batch around if we are doing ajax calls
      if request.xhr?
        self.batch = batch_sav.dup
        @key = params["key"]
        if @key != "permissions"
          @vals = params["generic_file"][@key]
        else
          @vals = [""]
        end
        render :update_edit
      end
    end

    protected

    # override this method if you need to initialize more complex RDF assertions (b-nodes)
    def initialize_fields(attributes, file)
       file.terms_for_editing.each do |key|
         # if value is empty, we create an one element array to loop over for output
         file[key] = attributes[key].empty? ? [''] : attributes[key]
       end
    end

    def redirect_to_return_controller
      if params[:return_controller]
        redirect_to sufia.url_for(controller: params[:return_controller], only_path: true)
      else
        redirect_to sufia.dashboard_index_path
      end
    end

  end
end
