require "om"
module Hydra::AssetsControllerHelper
  
  def apply_depositor_metadata(asset)
    if asset.respond_to?(:apply_depositor_metadata) && current_user.respond_to?(:login)
      asset.apply_depositor_metadata(current_user.login)
    end
  end

  def set_collection_type(asset, collection)
    if asset.respond_to?(:set_collection_type)
      asset.set_collection_type(collection)
    end
  end
  
  # 
  # parses your params hash, massaging them into an appropriate set of params and opts to pass into ActiveFedora::Base.update_indexed_attributes
  #
  def prep_updater_method_args(params)
    args = {:params=>{}, :opts=>{}}
    
    params["asset"].each_pair do |datastream_name,fields|
      
      args[:opts][:datastreams] = datastream_name
      
      # TEMPORARY HACK: special case for supporting textile 
      if params["field_id"]=="abstract_0" 
        params[:field_selectors] = {"descMetadata" => {"abstract" => [:abstract]}}
      end
      
      if params.fetch("field_selectors",false) && params["field_selectors"].fetch(datastream_name, false)
        # If there is an entry in field_selectors for the datastream (implying a nokogiri datastream), retrieve the field_selector for this field.
        # if no field selector, exists, use the field name
        fields.each_pair do |field_name,field_values|
          parent_select = OM.destringify( params["field_selectors"][datastream_name].fetch(field_name, field_name) )
          args[:params][parent_select] = field_values       
        end        
      else
        args[:params] = unescape_keys(params[:asset][datastream_name])
      end
    end
    
    return args
     
  end

  # moved destringify into OM gem. 
  # ie.  OM.destringify( params )
  # Note: OM now handles destringifying params internally.  You probably don't have to do it!
  
  private
    
  def send_datastream(datastream)
    send_data datastream.content, :filename=>datastream.label, :type=>datastream.attributes["mimeType"]
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