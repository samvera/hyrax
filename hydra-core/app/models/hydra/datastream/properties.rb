# properties datastream: catch-all for info that didn't have another home.  Particularly depositor.
module Hydra::Datastream
  class Properties < ActiveFedora::OmDatastream
    extend Deprecation

    def initialize(*)
      super
      Deprecation.warn(Properties, "Hydra::Datastream::Properties is deprecated and will be removed in hydra-head 10.0")
    end

    set_terminology do |t|
      t.root(:path=>"fields", :xmlns => '', :namespace_prefix => nil) 

      # This is where we put the user id of the object depositor -- impacts permissions/access controls
      t.depositor :xmlns => '', :namespace_prefix => nil

      # @deprecated  Collection should be tracked in RELS-EXT RDF.  collection term will be removed no later than release 6.x
      t.collection :xmlns => '', :namespace_prefix => nil
      # @deprecated  Title should be tracked in descMetadata.  title term will be removed no later than release 6.x
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
