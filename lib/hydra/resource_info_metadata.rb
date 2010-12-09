module Hydra
class ResourceInfoMetadata < ActiveFedora::NokogiriDatastream       
  
  set_terminology do |t|
    t.root(:path=>"file", :xmlns=>"http://hydra-collab.stanford.edu/schemas/resourceInfo/v1", :attributes=>{:id, :format, :mimetype, :size}){
      t.location(:path=>"location", :attribute=>"type")
	  t.checksum(:path=>"checksum", :attribute=>"type")
    }
  end
    
  # Generates an empty ResourceInfoMetadata (used when you call ResourceInfoMetadata.new without passing in existing xml)
  def self.xml_template
    builder = Nokogiri::XML::Builder.new do |xml|
	xml.file("xmlns"=>"http://hydra-collab.stanford.edu/schemas/resourceInfo/v1", :format=> "", :mimetype=>"", :size=>"") {
		xml.location(:type=>"")
		xml.checksum(:type=>"")
		}
    end
	
	logger.debug("nokogiri doc: #{builder.doc.inspect}")
	
    return builder.doc
  end 
  

  
end
end