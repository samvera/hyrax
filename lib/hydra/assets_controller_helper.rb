module Hydra::AssetsControllerHelper
  
  def retrieve_af_model(class_name)
    klass = Module.const_get(class_name.camelcase)
    #klass.included_modules.include?(ActiveFedora::Model)  
    if klass.is_a?(Class) && klass.superclass == ActiveFedora::Base
      return klass
    else
      return false
    end
    rescue NameError
      return false
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