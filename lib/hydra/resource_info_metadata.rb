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
	xml.file(:format=> "", :mimetype=>"", :size=>"") {
		xml.location(:type=>"")
		xml.checksum(:type=>"")
		}
    end
	
	logger.debug("nokogiri doc: #{builder.doc.inspect}")
	
    return builder.doc
  end 
  
    # Generates a new File node
    def self.file_template
      builder = Nokogiri::XML::Builder.new do |xml|
xml.file(:format=> "", :mimetype=>"", :size=>"") {
		xml.location(:type=>"")
		xml.checksum(:type=>"")
		}
      end
      return builder.doc.root
    end

    # Inserts a new file (<file>) into the resourceInfo document
    # creates contributors of type :person, :organization, or :conference
    def insert_file(type, opts={})
      case type.to_sym 
      when :file
        node = Hydra::ResourceInfoMetadata.file_template
        nodeset = self.find_by_terms(:person)
      else
        ActiveFedora.logger.warn("#{type} is not a valid argument for Hydra::ResourceInfoMetadata.insert_file")
        node = nil
        index = nil
      end
      
      unless nodeset.nil?
        if nodeset.empty?
          self.ng_xml.root.add_child(node)
          index = 0
        else
          nodeset.after(node)
          index = nodeset.length
        end
        self.dirty = true
      end
      
      return node, index
    end
    
    # Remove a file entry identified by @index
    def remove_file(index)
      self.find_by_terms( {type.to_sym => index.to_i} ).first.remove
      self.dirty = true
    end

end
end