class FileAsset < ActiveFedora::Base
  
  has_metadata :name => "DC", :type => ActiveFedora::QualifiedDublinCoreDatastream do |m|
  end
      
  def label=(label)
    super
    datastreams_in_memory["DC"].title_values = label
  end    
  
  def save
    super
    if defined?(Shelver::Shelver)
      shelver = Shelver::Shelver.new
      shelver.shelve_object( self )
    end
  end
  
end