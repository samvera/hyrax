# properties datastream: catch-all for info that didn't have another home.  Particularly depositor.
class PropertiesDatastream < ActiveFedora::NokogiriDatastream
  set_terminology do |t|
    t.root(:path=>"fields", :xmlns => '', :namespace_prefix => nil) 
    # This is where we put the user id of the object depositor -- impacts permissions/access controls
    t.depositor :xmlns => '', :namespace_prefix => nil
    # This is where we put the relative path of the file if submitted as a folder
    t.relative_path :xmlns => '', :namespace_prefix => nil
  end

  def self.xml_template
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.fields
    end
    builder.doc
  end
end
