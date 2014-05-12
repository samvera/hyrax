class CurationConcern::LinkedResourcesController < ApplicationController
  include Worthwhile::CurationConcernController
  set_curation_concern_type Worthwhile::LinkedResource

  respond_to(:html)

  include Worthwhile::ParentContainer
  before_filter :parent
  before_filter :authorize_edit_parent_rights!, except: [:show]


  def new
    respond_with(curation_concern)
  end

  def create
    curation_concern.batch = parent
    if actor.create
      respond_with([:curation_concern, parent])
    else
      respond_with([:curation_concern, curation_concern]) { |wants|
        wants.html { render 'new', status: :unprocessable_entity }
      }
    end
  end

  def edit
    respond_with(curation_concern)
  end

  def update
    if actor.update
      respond_with([:curation_concern, curation_concern])
    else
      respond_with([:curation_concern, curation_concern]) { |wants|
        wants.html { render 'edit', status: :unprocessable_entity }
      }
    end
  end

  def destroy
    parent = curation_concern.batch
    flash[:notice] = "Deleted #{curation_concern}"
    curation_concern.destroy
    respond_with([:curation_concern, parent])
  end

  def attach_action_breadcrumb
    add_breadcrumb "#{parent.human_readable_type}", polymorphic_path([:curation_concern, parent])
    super
  end

end
