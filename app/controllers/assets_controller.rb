require 'mediashelf/active_fedora_helper'

class AssetsController < ApplicationController
    include MediaShelf::ActiveFedoraHelper
    include Blacklight::SolrHelper
    include Hydra::RepositoryController
    include Hydra::AssetsControllerHelper
    include WhiteListHelper
    include ReleaseProcessHelper
    
    
    include Blacklight::CatalogHelper
    helper :hydra
    
    before_filter :search_session, :history_session
    before_filter :require_solr, :require_fedora
    
    prepend_before_filter :sanitize_update_params, :only=>:update
    before_filter :check_embargo_date_format, :only=>:update
        
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
    # @example Appends a new "subject" value of "My Topic" to on the descMetadata datastream in in the _PID_ document.
    #   put :update, :id=>"_PID_", "asset"=>{"descMetadata"=>{"subject"=>{"-1"=>"My Topic"}}
    # @example Sets the 1st and 2nd "medium" values on the descMetadata datastream in the _PID_ document, overwriting any existing values.
    #   put :update, :id=>"_PID_", "asset"=>{"descMetadata"=>{"medium"=>{"0"=>"Paper Document", "1"=>"Image"}}
    def update
      @document = load_document_from_params
      
      logger.debug("attributes submitted: #{@sanitized_params.inspect}")
           
      @response = update_document(@document, @sanitized_params)
     
      @document.save
      flash[:notice] = "Your changes have been saved."
      
      logger.debug("returning #{response.inspect}")
    
      respond_to do |want| 
        want.html {
          redirect_to :controller=>"catalog", :action=>"edit"
        }
        want.js {
          render :json=> tidy_response_from_update(@response)  
        }
        want.textile {
          if @response.kind_of?(Hash)
            textile_response = tidy_response_from_update(@response).values.first
          end
          render :text=> white_list( RedCloth.new(textile_response, [:sanitize_html]).to_html )
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
        model_display_name = af_model.to_s.camelize.scan(/[A-Z][^A-Z]*/).join(" ")
        msg = "Created a #{model_display_name} with pid #{@asset.pid}. Now it's ready to be edited."
        flash[:notice]= msg
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

    
    # This is a method to simply remove the item from SOLR but keep the object in fedora. 
    alias_method :withdraw, :destroy
    
    #def withdraw
    #  
    #end
    
end