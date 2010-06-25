module Hydra::AssetsControllerHelper
  
  def prep_updater_method_args(params)
    args = {:params=>{}, :opts=>{}}
    
    if params.has_key?("parent_select")
      args[:params][:parent_select] = destringify( params["parent_select"] )
      args[:params][:child_index] = destringify( params["child_index"] )
      args[:params][:values] = params[:value]
    else
      args[:params] = unescape_keys(params[:asset])
    end
    
    if params.has_key?("datastream")
      args[:opts][:datastreams] = params["datastream"]
    end
    
    return args
     
  end
  
  # @params String, Array, or Hash
  # Recursively changes any strings beginning with : to symbols and any number strings to integers
  # Converts [{":person"=>"0"}, ":last_name"] to [{:person=>0}, :last_name]
  def destringify(params)
    case params
    when String       
      if params == "0" || params.to_i != 0
        result = params.to_i
      elsif params[0,1] == ":"
        result = params.sub(":","").to_sym
      else
        result = params.to_sym
      end
      return result
    when Hash 
      result = {}
      params.each_pair do |k,v|
        result[ destringify(k) ] = destringify(v)
      end
      return result
    when Array 
      result = []
      params.each do |x|
        result << destringify(x)
      end
      return result
    else
      return params
    end
    
  end
  
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