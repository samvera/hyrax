module Worthwhile::ParentContainer
  extend ActiveSupport::Concern

  included do
    helper_method :parent
  end

  def parent
    @parent ||=
    if params[:id]
      curation_concern.batch
    else
      ActiveFedora::Base.find(namespaced_parent_id,cast: true)
    end
  end

  def namespaced_parent_id
    Sufia::Noid.namespaceize(params[:parent_id])
  end
  protected :namespaced_parent_id

  def authorize_edit_parent_rights!
    authorize! :edit, parent
  end
  protected :authorize_edit_parent_rights!

end
