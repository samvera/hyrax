# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController  

  include Blacklight::Catalog
  # Extend Blacklight::Catalog with Hydra behaviors (primarily editing).
  include Hydra::Catalog

  # These before_filters apply the hydra access controls
  before_filter :enforce_access_controls
  before_filter :enforce_viewing_context_for_show_requests, :only=>:show
  # This applies appropriate access controls to all solr queries
  CatalogController.solr_search_params_logic << :add_access_controls_to_solr_params
  # This filters out objects that you want to exclude from search results, like FileAssets
  CatalogController.solr_search_params_logic << :exclude_unwanted_models

  skip_before_filter :default_html_head
  
  def recent
      (resp, doc_list) = get_search_results(:q =>'', :sort=>"system_create_dt desc", :rows=>3)
      @recent_documents = doc_list[0..3]
  end

#####################
# jgm testing start #
#####################
  if Rails.env == "integration"
  # COPIED AND MODIFIED from:
  #	/usr/local/rvm/gems/ree-1.8.7-2011.03@scholarsphere/gems/blacklight-3.3.2/lib/blacklight/catalog.rb
  #
    # when solr (RSolr) throws an error (RSolr::RequestError), this method is executed.
    def rsolr_request_error(exception)
      #if Rails.env == "development"
      if ['development', 'integration'].include?(Rails.env)
        raise exception # Rails own code will catch and give usual Rails error page with stack trace
      else
        flash_notice = "Sorry, I don't understand your search."
        # Set the notice flag if the flash[:notice] is already set to the error that we are setting.
        # This is intended to stop the redirect loop error
        notice = flash[:notice] if flash[:notice] == flash_notice
        unless notice
          flash[:notice] = flash_notice
          redirect_to root_path, :status => 500
        else
          render :template => "public/500.html", :layout => false, :status => 500
        end
      end
    end
  #
  end
###################
# jgm testing end #
###################

end
