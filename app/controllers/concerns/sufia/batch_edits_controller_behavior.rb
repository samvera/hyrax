module Sufia
  module BatchEditsControllerBehavior
    extend ActiveSupport::Concern
    include Sufia::Breadcrumbs

    included do
      layout "sufia-one-column"
      before_action :build_breadcrumbs, only: :edit
    end

    def edit
      super
      @file_set = ::FileSet.new
      @file_set.depositor = current_user.user_key
      @terms = terms - [:title, :format, :resource_type]

      h = {}
      @names = []
      permissions = []

      # For each of the files in the batch, set the attributes to be the concatination of all the attributes
      batch.each do |doc_id|
        fs = ::FileSet.load_instance_from_solr(doc_id)
        terms.each do |key|
          h[key] ||= []
          h[key] = (h[key] + fs.send(key)).uniq
        end
        @names << fs.to_s
        permissions = (permissions + fs.permissions).uniq
      end

      initialize_fields(h, @file_set)

      @file_set.permissions_attributes = [{ type: 'group', name: 'public', access: 'read' }]
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
      obj.attributes = file_set_params
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
        batch.each { |id| ActiveFedora::Base.find(id).destroy }
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

      def file_set_params
        file_params = params[:file_set] || ActionController::Parameters.new
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
