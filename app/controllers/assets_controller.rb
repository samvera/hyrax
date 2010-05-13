require 'mediashelf/active_fedora_helper'

class AssetsController < ApplicationController
    include MediaShelf::ActiveFedoraHelper
    include Blacklight::SolrHelper
    include Hydra::RepositoryController
    
    
    include Blacklight::CatalogHelper
    helper :hydra, :metadata, :infusion_view
    
    before_filter :search_session, :history_session
    before_filter :require_solr, :require_fedora
    
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
      result.each_pair do |field_name,changed_values|
        changed_values.each_pair do |index,value|
          response["updated"] << {"field_name"=>field_name,"index"=>index,"value"=>value} 
        end
      end
      logger.debug("returning #{response.inspect}")
      respond_to do |want| 
        want.js {
          render :json=> response
        }
      end
    end
    
end