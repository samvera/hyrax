module Hydra
  module BatchEditBehavior
    extend ActiveSupport::Concern

    included do
      include Hyrax::Collections::AcceptsBatches

      before_action :filter_docs_with_access!, only: [:edit, :update, :destroy_collection]
      before_action :check_for_empty!, only: [:edit, :update, :destroy_collection]
    end

    # fetch the documents that match the ids in the folder
    def index
      @response, @documents = get_solr_response_for_field_values("id", batch)
    end

    def state
      session[:batch_edit_state] = params[:state]
      render json: { "OK" => "OK" }
    end

    def edit; end

    # pulled out to allow a user to override the default redirect
    def after_update
      redirect_to catalog_index_path
    end

    # called before the save of the document on update to do addition processes on the document beyond update_attributes
    def update_document(obj)
      type = obj.class.to_s.underscore.to_sym
      obj.update_attributes(params[type].reject { |_k, v| v.blank? })
    end

    def update
      batch.each do |doc_id|
        obj = ActiveFedora::Base.find(doc_id, cast: true)
        update_document(obj)
        obj.save
      end
      flash[:notice] = "Batch update complete"
      after_update
    end

    def all
      self.batch = Hyrax::Collections::SearchService.new(session, current_user.user_key).last_search_documents.map(&:id)
      respond_to do |format|
        format.html { redirect_to edit_batch_edits_path }
        format.js { render json: batch }
      end
    end

    # pulled out to allow a user to override the default redirect
    def after_destroy_collection
      redirect_to catalog_index_path
    end

    def destroy_collection
      batch.each do |doc_id|
        obj = ActiveFedora::Base.find(doc_id, cast: true)
        obj.destroy
      end
      flash[:notice] = "Batch delete complete"
      after_destroy_collection
    end

    def check_for_empty!
      return unless check_for_empty_batch?
      redirect_back fallback_location: hyrax.batch_edits_path
      false
    end
  end
end
