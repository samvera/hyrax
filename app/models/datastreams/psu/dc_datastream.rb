module Psu
class DcDatastream < ActiveFedora::NokogiriDatastream
  
  set_terminology do |t|
    t.root(:path=>"dc", :xmlns=>'http://purl.org/dc/terms/', 'xmlns:ical' => 'http://www.w3.org/2002/12/cal#', "xmlns:cpf"=>"urn:isbn:1-931666-33-4")
    
    # Title variations
    t.english_title(:path=>"title", :attributes=>{'xml:lang'=>"eng"})
    t.tibetan_title(:path=>"title", :attributes=>{'xml:lang'=>"tib", 'cpf:scriptCode'=>"Tibt"})
    t.wylie_title(:path=>"title", :attributes=>{'xml:lang'=>"tib", 'cpf:scriptCode'=>"Latn", 'cpf:transliteration'=>'wylie'})
    t.wylie_title(:path=>"title", :attributes=>{'xml:lang'=>"tib", 'cpf:scriptCode'=>"Latn", 'cpf:transliteration'=>'wylie'})
    t.marpa_transliteration_title(:path=>"title", :attributes=>{'xml:lang'=>"tib", 'cpf:scriptCode'=>"Latn", 'cpf:transliteration'=>'marpa'})
    t.sanskrit_title(:path=>"title", :attributes=>{'xml:lang'=>"skt", 'cpf:scriptCode'=>"Latn", 'cpf:transliteration'=>'marpa'})
    t.sanskrit_diacrit_title(:path=>"title", :attributes=>{'xml:lang'=>"skt", 'cpf:scriptCode'=>"Latn", 'cpf:transliteration'=>nil})
    
    t.contributor(:index_as=>[:facetable])
    t.creator
    t.description
    t.format
    t.identifier
    t.language(:index_as=>[:facetable])
    t.publisher
    t.relation
    t.source
    t.title
    t.abstract
    t.accessRights
    t.accrualMethod
    t.accrualPeriodicity
    t.accrualPolicy
    t.alternative
    t.audience
    t.available
    t.bibliographicCitation
    t.conformsTo
    t.contributor
    t.coverage
    t.created
    t.date(:index_as=>[:not_searchable]) {
      t.vevent(:namespace_prefix =>'ical', :path=>'Vevent', :index_as=>[:not_searchable]) {
        t.dtstart(:namespace_prefix=>'ical', :path=>'dtstart', :index_as=>[:facetable])
        t.dtend(:namespace_prefix=>'ical')
      }
    }
    t.start_date(:proxy=>[:date, :vevent, :dtstart])
    t.end_date(:proxy=>[:date, :vevent, :dtend])
    t.duration(:proxy=>[:coverage])
    t.dateAccepted
    t.dateCopyrighted
    t.dateSubmitted
    t.description
    t.educationLevel
    t.extent
    t.format
    t.hasFormat
    t.hasPart
    t.hasVersion
    t.identifier
    t.instructionalMethod
    t.isFormatOf
    t.isPartOf
    t.isReferencedBy
    t.isReplacedBy
    t.isRequiredBy
    t.issued
    t.isVersionOf
    t.license
    t.mediator
    t.medium
    t.modified
    t.provenance
    t.publisher
    t.references
    t.relation
    t.replaces
    t.requires
    t.rights
    t.rightsHolder
    t.source
    t.spatial(:index_as=>[:facetable])
    t.subject(:index_as=>[:facetable])
    t.tableOfContents
    t.temporal
    t.type_
    t.valid
  end
  
  def self.xml_template
    # builder = Nokogiri::XML::Builder.new do |xml|
    #   xml.dc("xmlns"=>'http://purl.org/dc/terms/',
    #     "xmlns:dcterms"=>'http://purl.org/dc/terms/', 
    #     "xmlns:xsi"=>'http://www.w3.org/2001/XMLSchema-instance',
    #     "xmlns:cpf"=>"urn:isbn:1-931666-33-4") {
    #   }
    # end
    # return builder.doc
    doc = Nokogiri::XML::Document.parse( File.new(File.join(File.dirname(__FILE__), 'marpa_dc_datastream_template.xml')) )
  end
  
  # Extending update_indexed_attributes 
  def update_indexed_attributes(params={}, opts={}) 
    apply_legacy_xml_fixes
    super
  end
  
  def apply_legacy_xml_fixes
    # Clean up old xml documents that don't have all of the necessary namespaces declared
    unless self.ng_xml.namespaces.has_key?("xmlns:ical")
      self.ng_xml.root.add_namespace("ical",'http://www.w3.org/2002/12/cal#')
    end
  end
  
end
end
