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
module MediaShelf
  module ActiveFedoraHelper

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

  end
end
