# Hydra-repository Contoller is a controller layer mixin. It is in the controller scope: request params, session etc.
# 
# NOTE: Be careful when creating variables here as they may be overriding something that already exists.
# The ActionController docs: http://api.rubyonrails.org/classes/ActionController/Base.html
#
# Override these methods in your own controller for customizations:
# 
# class HomeController < ActionController::Base
#   
#   include Stanford::SolrHelper
#   
#   def solr_search_params
#     super.merge :per_page=>10
#   end
#   
# end
#
module Hydra::RepositoryController
  
  def self.included(c)
    if c.respond_to?(:helper_method)
      c.helper_method :solr_name
      c.helper_method :format_pid
    end
  end
  
  
  #
  # This method converts pid strings into xhtml safe IDs, since xhmlt expects namespaces to be defined. 
  # I.E. hydrus:123 = hydrus_123
  def format_pid(pid)
    pid.gsub(":", "_")
  end
  
  
  
  def solr_name(field_name, field_type = :text)
    ::ActiveFedora::SolrService.solr_name(field_name, field_type)
  end
  
  # Uses submitted params Hash to figure out what Model to load
  # params should contain :content_type and :id
  def load_document_from_params
    af_model = retrieve_af_model(params[:content_type])
    unless af_model 
      af_model = ModsAsset
    end
    return af_model.find(params[:id])
  end
  
  # Returns a list of datastreams for download.
  # Uses user's roles and "mime_type" value in submitted params to decide what to return.
  # if you pass the optional argument of :canonical=>true, it will return the canonical datastream for this object (a single object not a hash of datastreams)
  def downloadables(fedora_object=@fedora_object, opts={})
    if opts[:canonical]
      mime_type = opts[:mime_type] ? opts[:mime_type] : "application/pdf"
      result = filter_datastreams_for_mime_type(fedora_object.datastreams, mime_type).sort.first[1]
    elsif editor? 
      if params["mime_type"] == "all"
        result = fedora_object.datastreams
      else
        result = Hash[]
        fedora_object.datastreams.each_pair do |dsid,ds|
          if !ds.new_object?
            mime_type = ds.mimeType ? ds.mimeType : ""
            if mime_type.include?("pdf") || ds.label.include?("_TEXT.xml") || ds.label.include?("_METS.xml")
             result[dsid] = ds
            end 
          end 
        end
      end
    else
      result = Hash[]
      fedora_object.datastreams.each_pair do |dsid,ds|
         if ds.mimeType.include?("pdf")
           result[dsid] = ds
         end  
       end
    end 
    # puts "downloadables result: #{result}"
    return result    
  end

  protected 
  
  def retrieve_af_model(class_name, opts={})
    if !class_name.nil?
      klass = Module.const_get(class_name.camelcase)
    else
      klass = nil
    end
    if klass.is_a?(Class) && klass.superclass == ActiveFedora::Base
      return klass
    else
      return opts.fetch(:default, false)
    end
    rescue NameError
      return false
  end

  def load_af_instance_from_solr(doc)
    pid = doc[:id] ? doc[:id] : doc[:id.to_s]
    pid ? ActiveFedora::Base.load_instance_from_solr(pid,doc) : nil
  end
  
  private
  
  def filter_datastreams_for_mime_type(datastreams_hash, mime_type)
    result = Hash[]
    datastreams_hash.each_pair do |dsid,ds|
      ds_mime_type = ds.mimeType ? ds.mimeType : ""
      if ds_mime_type == mime_type
       result[dsid] = ds
      end  
    end
    return result
  end
end
