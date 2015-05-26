module CurationConcerns::ParentContainer
  extend ActiveSupport::Concern

  included do
    helper_method :parent
    before_filter :authorize_edit_parent_rights!, except: [:show]
  end

  def parent
    @parent ||= new_or_create? ? ActiveFedora::Base.find(parent_id) : curation_concern.batch
  end

  def parent_id
    @parent_id ||= new_or_create? ? params[:parent_id] : curation_concern.batch_id
  end

  protected

    def new_or_create?
      ['create', 'new'].include? action_name
    end

    def namespaced_parent_id
      # Sufia::Noid.namespaceize(params[:parent_id])
    end

    def authorize_edit_parent_rights!
      authorize! :edit, parent_id
    end

end
