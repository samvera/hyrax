require "om"
module Hydra::AssetsControllerHelper
  
  def prep_updater_method_args(params)
    args = {:params=>{}, :opts=>{}}
    
    params["asset"].each_pair do |datastream_name,fields|
      
      args[:opts][:datastreams] = datastream_name
      
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
    
    # if params.has_key?("parent_select")
    #   args[:params][:parent_select] = destringify( params["parent_select"] )
    #   args[:params][:child_index] = destringify( params["child_index"] )
    #   args[:params][:values] = params[:value]
    # else
    #   args[:params] = unescape_keys(params[:asset])
    # end
    
    # if params.has_key?("datastream")
    #   args[:opts][:datastreams] = params["datastream"]
    # end
    
    return args
     
  end

  # moved destringify into OM gem. 
  # ie.  OM.destringify( params )
  # Note: OM now handles destringifying params internally.  You probably don't have to do it!
  
  private
    
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