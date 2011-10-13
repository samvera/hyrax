require "hydra-head" # This is a hacky way of ensuring that require_plugin_dependency is defined.
module Blacklight

  require_plugin_dependency "vendor/plugins/blacklight/lib/blacklight.rb"
  
 # This method overrides the default Blacklight self.init in order to support the opention of dual default/fulltext indexing
 # that's supported in hydrangea. This also supports the traditional one index structure of Blacklight.  

 def self.init
    
    solr_config = YAML::load(File.open("#{RAILS_ROOT}/config/solr.yml"))
    raise "The #{RAILS_ENV} environment settings were not found in the solr.yml config" unless solr_config[RAILS_ENV]
    
    if solr_config[RAILS_ENV].has_key?("default")
      Blacklight.solr_config[:url] = solr_config[RAILS_ENV]['default']['url']
    elsif solr_config[RAILS_ENV].has_key?('url') 
      Blacklight.solr_config[:url] = solr_config[RAILS_ENV]['url']
    else
      raise "BLACKLIGHT: Unable to configure solr -- #{solr_config.inspect}"
    end
    
    if Gem.available? 'curb'
      require 'curb'
      Blacklight.solr = RSolr::Ext.connect(Blacklight.solr_config.merge(:adapter=>:curb))
    else
      Blacklight.solr = RSolr::Ext.connect(Blacklight.solr_config)
    end
    
    # set the SolrDocument.connection to Blacklight.solr
    SolrDocument.connection = Blacklight.solr
    logger.info("BLACKLIGHT: running version #{Blacklight.version}")
    logger.info("BLACKLIGHT: initialized with Blacklight.solr_config: #{Blacklight.solr_config.inspect}")
    logger.info("BLACKLIGHT: initialized with Blacklight.solr: #{Blacklight.solr.inspect}")
    logger.info("BLACKLIGHT: initialized with Blacklight.config: #{Blacklight.config.inspect}")
    
  end
  
  
  
end