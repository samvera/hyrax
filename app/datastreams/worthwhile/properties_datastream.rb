# properties datastream: catch-all for info that didn't have another home.
class Worthwhile::PropertiesDatastream < ActiveFedora::OmDatastream
  set_terminology do |t|
    t.root(:path=>"fields" ) 
    # This is where we put the user id of the object depositor
    t.depositor index_as: :stored_searchable
    t.owner

    # Although we aren't using these fields, they are required because sufia-models delegates to them.
    t.relative_path 
    t.import_url 

    #This attribute should hold the selected file which represent the work.
    t.representative index_as: :symbol
  end

  def self.xml_template
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.fields
    end
    builder.doc
  end

  def prefix
    'properties_'
  end
end

