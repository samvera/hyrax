class CurationConcern::LinkedResourcesController < ApplicationController
  include Worthwhile::ThemedLayoutController
  with_themed_layout '1_column'
  respond_to(:html)

  load_and_authorize_resource class: Worthwhile::LinkedResource, instance_name: :curation_concern
  include Worthwhile::ParentContainer

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
      respond_with([:curation_concern, curation_concern.batch])
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

  attr_writer :actor
  def actor
    @actor ||= Worthwhile::CurationConcern.actor(curation_concern, current_user, params[:linked_resource])
  end

  def curation_concern
    @curation_concern
  end

  helper_method :curation_concern

  protected
    def _prefixes
      # This allows us to use the unauthorized template in curation_concern/base
      @_prefixes ||= super + ['curation_concern/base']
    end

end
