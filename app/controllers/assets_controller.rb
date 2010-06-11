require 'mediashelf/active_fedora_helper'

class AssetsController < ApplicationController
    include MediaShelf::ActiveFedoraHelper
    include Blacklight::SolrHelper
    include Hydra::RepositoryController
    include Hydra::AssetsControllerHelper
    include WhiteListHelper
    
    
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
            result = result[params["field_index"].to_i]
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
        af_model = SaltDocument
      end
      @document = af_model.find(params[:id])
      
      attrs = unescape_keys(params[af_model.to_s.underscore])
      logger.debug("attributes submitted: #{attrs.inspect}")
      result = @document.update_indexed_attributes(attrs)
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
          render :text=> white_list( RedCloth.new(response, [:sanitize_html]).to_html )
        }
      end
    end
    
    def new
      af_model = retrieve_af_model(params[:content_type])
      if af_model
        @asset = af_model.new
        @asset.save
      end
      redirect_to url_for(:action=>"edit", :controller=>"catalog", :id=>@asset.pid)
    end
    
end