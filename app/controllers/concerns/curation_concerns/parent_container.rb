module CurationConcerns::ParentContainer
  extend ActiveSupport::Concern

  included do
    helper_method :parent
    # before_filter :authorize_edit_parent_rights!, except: [:show]  # Not sure we actually want this enforced any more (was originally in worthwhile), especially since GenericFiles and GenericWorks (which are PCDM::Objects)can belong to multiple parents
  end

  def parent
    @parent ||= new_or_create? ? ActiveFedora::Base.find(parent_id) : curation_concern.parent_objects.first # parent_objects method is inherited from Hydra::PCDM::ObjectBehavior
  end

  def parent_id
    @parent_id ||= new_or_create? ? params[:parent_id] : curation_concern.generic_works.parent_objects.first.id
  end

  protected

    def new_or_create?
      %w(create new).include? action_name
    end

    def namespaced_parent_id
      # Sufia::Noid.namespaceize(params[:parent_id])
    end

    # restricts edit access so that you can only edit a record if you can also edit its parent.

    def authorize_edit_parent_rights!
      authorize! :edit, parent_id
    end
end
