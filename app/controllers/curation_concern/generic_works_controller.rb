module CurationConcern
  class GenericWorksController < ApplicationController
    include Worthwhile::CurationConcernController
    include Sufia::Controller
    set_curation_concern_type GenericWork

    def generic_work_params
      form_class.model_attributes(
          params.require(:generic_work).permit(:title, :description, :members, part_of: [],
          contributor: [], creator: [], publisher: [], date_created: [], subject: [],
          language: [], rights: [], resource_type: [], identifier: [], based_near: [],
          tag: [], related_url: [])
      )
    end

    def form_class
      Sufia::Forms::GenericWorkEditForm
    end

    def presenter_class
      Sufia::GenericWorkPresenter
    end

    # Override this method if you wish to customize the way access is denied
    def deny_access(exception)
      if exception.action == :edit
        redirect_to sufia.url_for({ action: 'show' }), alert: exception.message
      else
        super
      end
    end


    def after_create_response
      puts "\n\nparams #{params[:save_with_files]}"
      if params[:save_with_files].blank?
        redirect_to sufia.generic_work_path(curation_concern.id)
      else
        redirect_to sufia.new_generic_file_path work_id: curation_concern.id
      end
    end

  end
end