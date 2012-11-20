require "hydra/submission_workflow"
require 'deprecation' 

module Hydra::HydraHelperBehavior
  include Hydra::SubmissionWorkflow
  
  
  def edit_and_browse_links
    result = ""
    if params[:action] == "edit"
      result << "<a href=\"#{catalog_path(@document[:id], :viewing_context=>"browse")}\" class=\"browse toggle\">Switch to browse view</a>"
    else
      result << "<a href=\"#{edit_catalog_path(@document[:id], :viewing_context=>"edit")}\" class=\"edit toggle\">Switch to edit view</a>"
    end
    return result.html_safe
  end
  
  # @deprecated
  def grouping_facet
    Deprecation.warn Hydra::HydraHelperBehavior, "Grouping facet will be removed in hydra-file-access 6.0"
    fields = Hash[sort_fields]
    case h(params[:sort])
    when fields['date -']
      'year_facet'
    when fields['date +']
      'year_facet'
    when fields['document type']
      'medium_t'
    when fields['location']
      'series_facet'
    else
      nil
    end
  end
  
  def document_fedora_show_html_title
    @document.datastreams["descMetadata"].title_values.first
  end
  
  
  def render_previous_workflow_steps
    previous_show_partials(params[:wf_step]).map{|partial| render partial}.join
  end
  
  def render_submission_workflow_step
    if params.has_key?(:wf_step)
      render workflow_partial_for_step(params[:wf_step])
    else
      render workflow_partial_for_step(first_step_in_workflow)
    end
  end
  

  def render_all_workflow_steps
    all_edit_partials.map{|partial| render partial}.join
  end
  
  def submit_name
    if session[:scripts]
      return "Save"
    elsif params[:new_asset]
      return "Continue"
    else
      return "Save and Continue"
    end
  end

  ### TODO this method is also in Hydra::Controller -- DRY it out
  def user_key
    current_user.user_key
  end

end
