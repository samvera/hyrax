class FileAsset < ActiveFedora::Base
  
  has_metadata :name => "DC", :type => ActiveFedora::QualifiedDublinCoreDatastream do |m|
  end
      
  def label=(label)
    super
    datastreams_in_memory["DC"].title_values = label
  end    
  
  def save
    super
    if defined?(Solrizer::Solrizer)
      solrizer = Solrizer::Solrizer.new
      solrizer.solrize( self )
    end
  end
  
end