require "om"
# TODO: All of this should be moved into module Hydra::Assets and this file should be eliminated.
module Hydra::AssetsControllerHelper
  
  # This makes sure that assets have the current user marked as their depositor/owner.  
  # Relies on the asset's model to define _what_ apply_depositor_metadata should do.  Most Hydra assets will rely on {Hydra::ModelMethods#apply_depositor_metadata}
  #
  # Attempts to call apply_depositor_metadata on the +asset+, passing user_key as the depositor
  # Does nothing if the asset doesn't respond to .apply_depositor_metadata 
  # @param asset to call apply_depositor_metadata on
  def apply_depositor_metadata(asset)
    if asset.respond_to?(:apply_depositor_metadata) && user_key
      asset.apply_depositor_metadata(user_key)
    end
  end

  def set_collection_type(asset, collection)
    if asset.respond_to?(:set_collection_type)
      asset.set_collection_type(collection)
    end
  end
  
  # Builds a Hash that you can feed into ActiveFedora::Base.update_datstream_attributes
  # If params[:asset] is empty, returns an empty Hash
  # @return [Hash] a Hash that you can feed into ActiveFedora::Base.update_datstream_attributes
  #   {
  #    "descMetadata"=>{ [{:person=>0}, :role]=>{"0"=>"role1", "1"=>"role2", "2"=>"role3"} },
  #    "properties"=>{ "notes"=>"foo" }
  #   }
  def sanitize_update_params
    @sanitized_params ||= {}
    
    unless params["asset"].nil?
      params["asset"].each_pair do |datastream_name,fields|
      
        @sanitized_params[datastream_name] = {}
      
        # TEMPORARY HACK: special case for supporting textile 
        if params["field_id"]=="abstract_0" 
          params[:field_selectors] = {"descMetadata" => {"abstract" => [:abstract]}}
        end
      
        if params.fetch("field_selectors",false) && params["field_selectors"].fetch(datastream_name, false)
          # If there is an entry in field_selectors for the datastream (implying a nokogiri datastream), retrieve the field_selector for this field.
          # if no field selector, exists, use the field name
          fields.each_pair do |field_name,field_values|
            parent_select = OM.destringify( params["field_selectors"][datastream_name].fetch(field_name, field_name) )
            # calling on unique because duplicate keys can be problematic for multi-valued fields. (HYDRA-785)
            parent_select.uniq! if parent_select.respond_to?(:uniq!)
            
            @sanitized_params[datastream_name][parent_select] = field_values       
          end        
        else
          @sanitized_params[datastream_name] = unescape_keys(params[:asset][datastream_name])
        end
      end
    end
    
    return @sanitized_params
  end
  
  # Tidies up the response from updating the document, making it more JSON-friendly
  # @param [Hash] response_from_update the response from updating the object's values
  # @return [Hash] A Hash where value of "updated" is an array with fieldname / index / value Hash for each field updated
  def tidy_response_from_update(response_from_update)
    response = Hash["updated"=>[]]
    last_result_value = ""
    response_from_update.each_pair do |field_name,changed_values|
      changed_values.each_pair do |index,value|
        response["updated"] << {"field_name"=>field_name,"index"=>index,"value"=>value} 
        last_result_value = value
      end
    end
    # If handling submission from jeditable (which will only submit one value at a time), return the value it submitted
    if params.has_key?(:field_id)
      response = last_result_value
    end
    return response
  end
  
  
  # Updates the document based on the provided parameters
  # This method can be overridden to perform additional update work in the hydra head.
  # @param [ActiveFedora::Base] document
  # @param [Hash] params should be the type expected by ActiveFedora::Base.update_datastream_attributes
  def update_document(document, params)
    # this will only work if there is only one datastream being updated.
    # once ActiveFedora::MetadataDatastream supports .update_datastream_attributes, use that method instead (will also be able to pass through params["asset"] as-is without usin prep_updater_method_args!)
    # result = document.update_indexed_attributes(params[:params], params[:opts])
    result = document.update_datastream_attributes(params)
  end
  
  # moved destringify into OM gem. 
  # ie.  OM.destringify( params )
  # Note: OM now handles destringifying params internally.  You probably don't have to do it!
  
  private
  
  
  def send_datastream(datastream)
    self.send_data datastream.content, :filename=>datastream.dsLabel, :type=>datastream.mimeType
  end
  
  #underscores are escaped w/ + signs, which are unescaped by rails to spaces
  def unescape_keys(attrs)
    h=Hash.new
    attrs.each do |k,v|
      h[k.gsub(/ /, '_')]=v

    end
    h
  end
  def escape_keys(attrs)
    h=Hash.new
    attrs.each do |k,v|
      h[k.gsub(/_/, '+')]=v

    end
    h
  end
  
end
