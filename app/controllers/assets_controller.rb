require 'mediashelf/active_fedora_helper'

class AssetsController < ApplicationController
    include MediaShelf::ActiveFedoraHelper
    include Blacklight::SolrHelper
    include Hydra::RepositoryController
    include Hydra::AssetsControllerHelper
    include WhiteListHelper
    include ReleaseProcessHelper
    
    
    include Blacklight::CatalogHelper
    helper :hydra, :metadata, :infusion_view
    
    before_filter :search_session, :history_session
    before_filter :require_solr, :require_fedora
    
    def show
      if params.has_key?("field")
        
        @response, @document = get_solr_response_for_doc_id
        # @document = SolrDocument.new(@response.docs.first)
        result = @document["#{params["field"]}_t"]
        # document_fedora = SaltDocument.load_instance(params[:id])
        # result = document_fedora.datastreams_in_memory[params["datastream"]].send("#{params[:field]}_values")
        unless result.nil?
          if params.has_key?("field_index")
            result = result[params["field_index"].to_i-1]
          elsif result.kind_of?(Array)
            result = result.first
          end
        end
        respond_to do |format|
          format.html     { render :text=>result }
          format.textile  { render :text=> white_list( RedCloth.new(result, [:sanitize_html]).to_html ) }
        end
      else
        redirect_to :controller=>"catalog", :action=>"show"
      end
    end
    
    # Uses the update_indexed_attributes method provided by ActiveFedora::Base
    # This should behave pretty much like the ActiveRecord update_indexed_attributes method
    # For more information, see the ActiveFedora docs.
    # 
    # Examples
    # put :update, :id=>"_PID_", "document"=>{"subject"=>{"-1"=>"My Topic"}}
    # Appends a new "subject" value of "My Topic" to any appropriate datasreams in the _PID_ document.
    # put :update, :id=>"_PID_", "document"=>{"medium"=>{"1"=>"Paper Document", "2"=>"Image"}}
    # Sets the 1st and 2nd "medium" values on any appropriate datasreams in the _PID_ document, overwriting any existing values.
    def update
      af_model = retrieve_af_model(params[:content_type])
      unless af_model 
        af_model = HydrangeaArticle
      end
      @document = af_model.find(params[:id])
            
      updater_method_args = prep_updater_method_args(params)
      @document.update_from_computing_id(params)
      check_embargo_date_format
      
      logger.debug("attributes submitted: #{updater_method_args.inspect}")
      # this will only work if there is only one datastream being updated.
      # once ActiveFedora::MetadataDatastream supports .update_datastream_attributes, use that method instead (will also be able to pass through params["asset"] as-is without usin prep_updater_method_args!)
      result = @document.update_indexed_attributes(updater_method_args[:params], updater_method_args[:opts])
      @document.save
      #response = attrs.keys.map{|x| escape_keys({x=>attrs[x].values})}
      response = Hash["updated"=>[]]
      last_result_value = ""
      result.each_pair do |field_name,changed_values|
        changed_values.each_pair do |index,value|
          response["updated"] << {"field_name"=>field_name,"index"=>index,"value"=>value} 
          last_result_value = value
        end
      end
      logger.debug("returning #{response.inspect}")
    
      # If handling submission from jeditable (which will only submit one value at a time), return the value it submitted
      if params.has_key?(:field_id)
        response = last_result_value
      end
    
      respond_to do |want| 
        want.js {
          render :json=> response
        }
        want.textile {
          if response.kind_of?(Hash)
            response = response.values.first
          end
          render :text=> white_list( RedCloth.new(response, [:sanitize_html]).to_html )
        }
      end
    end
    
    def new
      af_model = retrieve_af_model(params[:content_type])
      if af_model
        @asset = af_model.new
        apply_depositor_metadata(@asset)
        set_collection_type(@asset, params[:content_type])
        @asset.save
      end
      redirect_to url_for(:action=>"edit", :controller=>"catalog", :id=>@asset.pid)
    end
    
    def destroy
      af = ActiveFedora::Base.load_instance_from_solr(params[:id])
      the_model = ActiveFedora::ContentModel.known_models_for( af ).first
      unless the_model.nil?
        af = the_model.load_instance_from_solr(params[:id])
        assets = af.destroy_child_assets
      end
      af.delete
      msg = "Deleted #{params[:id]}"
      msg.concat(" and associated file_asset(s): #{assets.join(", ")}") unless assets.empty?
      flash[:notice]= msg
      redirect_to url_for(:action => 'index', :controller => "catalog", :q => nil , :f => nil)
    end
    
end