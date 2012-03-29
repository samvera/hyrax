module Hydra::Datastream
  class Properties < ActiveFedora::NokogiriDatastream
    set_terminology do |t|
      t.root(:path=>"fields", :xmlns => '', :namespace_prefix => nil) 

      t.collection :xmlns => '', :namespace_prefix => nil
      t.depositor :xmlns => '', :namespace_prefix => nil
      t.title :xmlns => '', :namespace_prefix => nil
    end

    def self.xml_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.fields
      end

      builder.doc
    end
  end
end
