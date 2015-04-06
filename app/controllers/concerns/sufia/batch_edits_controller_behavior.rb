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
       @terms = terms - [:title, :format, :resource_type]

       h  = {}
       @names = []
       permissions = []

       # For each of the files in the batch, set the attributes to be the concatination of all the attributes
       batch.each do |doc_id|
          gf = ::GenericFile.load_instance_from_solr(doc_id)
          terms.each do |key|
            h[key] ||= []
            h[key] = (h[key] + gf.send(key)).uniq
          end
          @names << gf.to_s
          permissions = (permissions + gf.permissions).uniq
       end

       initialize_fields(h, @generic_file)

       @generic_file.permissions_attributes = [{type: 'group', name: 'public', access: 'read'}]
    end

    def after_update

      respond_to do |format|
        format.json { head :no_content }
        format.html { redirect_to_return_controller }
      end
    end

    def after_destroy_collection
      redirect_to_return_controller unless request.xhr?
    end

    def update_document(obj)
      obj.attributes = generic_file_params
      obj.date_modified = Time.now.ctime
      obj.visibility = params[:visibility]
    end

    def update
      case params["update_type"]
        when "update"
          super
        when "delete_all"
          destroy_batch
      end
    end

    protected

    def destroy_batch
      batch.each do |doc_id|
        gf = ::GenericFile.find(doc_id)
        gf.destroy
      end
      after_update
    end

    # override this method if you need to initialize more complex RDF assertions (b-nodes)
    def initialize_fields(attributes, file)
       terms.each do |key|
         # if value is empty, we create an one element array to loop over for output
         file[key] = attributes[key].empty? ? [''] : attributes[key]
       end
    end

    def terms
      Forms::BatchEditForm.terms
    end

    def generic_file_params
      file_params = params[:generic_file] || ActionController::Parameters.new()
      Forms::BatchEditForm.model_attributes(file_params)
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
