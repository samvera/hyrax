module Hydra
  class ModsDataset < ActiveFedora::NokogiriDatastream

    # have to call this in order to set namespace & schema
    root_property :mods, "mods", "http://www.loc.gov/mods/v3", :attributes=>["id", "version"], :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"          

    property :title_info, :path=>"titleInfo", 
                :convenience_methods => {
                  :main_title => {:path=>"title"},
                  # :language => {:path=>{:attribute=>"lang"}},    
                  :language => {:path=>"language"},                 
                }
    
    property :note, :path=>"note"
    property :completeness, :variant_of=>:note, :attributes=>{:type=>"completeness"}
    property :interval, :variant_of=>:note, :attributes=>{:type=>"interval"}
    property :data_type, :variant_of=>:note, :attributes=>{:type=>"datatype"}
    property :timespan_start, :variant_of=>:note, :attributes=>{:type=>"timespan-start"}
    property :timespan_end, :variant_of=>:note, :attributes=>{:type=>"timespan-end"}
    property :location, :variant_of=>:note, :attributes=>{:type=>"location"}
    property :grant_number, :variant_of=>:note, :attributes=>{:type=>"grant"}
    property :data_quality, :variant_of=>:note, :attributes=>{:type=>"data quality"}
    property :contact_name, :variant_of=>:note, :attributes=>{:type=>"contact-name"}
    property :contact_email, :variant_of=>:note, :attributes=>{:type=>"contact-email"}
    
    property :methodology, :path=>"abstract"
                
    property :name_, :path=>"name", 
                :attributes=>[:xlink, :lang, "xml:lang", :script, :transliteration, {:type=>["personal", "corporate", "conference"]} ],
                :subelements=>["namePart", "displayForm", "affiliation", :role, "description"],
                :default_content_path => "namePart",
                :convenience_methods => {
                  :last_name => {:path=>"namePart", :attributes=>{:type=>"family"}},
                  :first_name => {:path=>"namePart", :attributes=>{:type=>"given"}},
                  :institution=>{:path=>'affiliation'}
                }
    property :person, :variant_of=>:name_, :attributes=>{:type=>"personal"}
    property :organization, :variant_of=>:name_, :attributes=>{:type=>"corporate"}
    
    property :role, :path=>"role",
                :parents=>[:name_],
                :convenience_methods => {
                  :text => {:path=>"roleTerm", :attributes=>{:type=>"text"}},
                  :code => {:path=>"roleTerm", :attributes=>{:type=>"code"}},                    
                }
    
    property :subject, :path=>'subject',:subelements => "topic"    

    # It would be nice if we could declare properties with refined info like this
    # accessor :grant_agency,  :relative_xpath=>'oxns:mods/oxns:name[contains(oxns:role/oxns:roleTerm, "Funder")]'

    generate_accessors_from_properties  
  
    # Generates an empty Mods Article (used when you call ModsArticle.new without passing in existing xml)
    def self.xml_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.mods(:version=>"3.3", "xmlns:xlink"=>"http://www.w3.org/1999/xlink",
           "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
           "xmlns"=>"http://www.loc.gov/mods/v3",
           "xsi:schemaLocation"=>"http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd") {
             xml.titleInfo {
               xml.title
             }
             xml.name(:type=>"personal") {
               xml.namePart(:type=>"given")
               xml.namePart(:type=>"family")
               xml.affiliation
               xml.role {
                 xml.roleTerm(:authority=>"marcrelator", :type=>"text")
               }
             }
             xml.name(:type=>"corporate") {
               xml.namePart
               xml.affiliation
               xml.role {
                 xml.roleTerm("Funder", :authority=>"marcrelator", :type=>"text") 
               }
             }
             xml.typeOfResource "software, multimedia"
             xml.genre("dataset", :authority=>"dct")
             xml.language {
               xml.languageTerm("eng", :authority=>"iso639-2b", :type=>"code")
             }
             xml.abstract
             xml.subject {
               xml.topic
             }
             xml.note(:type=>"completeness")
             xml.note(:type=>"interval")
             xml.note(:type=>"datatype")
             xml.note(:type=>"timespan-start")
             xml.note(:type=>"timespan-end")
             xml.note(:type=>"location")
             xml.note(:type=>"grant")
             xml.note(:type=>"data quality")
             xml.note(:type=>"contact-name")
             xml.note(:type=>"contact-email")
        }
      end
      return builder.doc
    end

    def self.person_relator_terms
       {"anl" => "Analyst",
        "aut" => "Author",
        "clb" => "Collaborator",
        "com" => "Compiler",
        "cre" => "Creator",
        "ctb" => "Contributor",
        "dpt" => "Depositor",
        "dtc" => "Data contributor ",
        "dtm" => "Data manager ",
        "edt" => "Editor",
        "lbr" => "Laboratory ",
        "ldr" => "Laboratory director ",
        "pdr" => "Project director",
        "prg" => "Programmer",
        "res" => "Researcher",
        "rth" => "Research team head",
        "rtm" => "Research team member"
        }
    end
    
    def self.interval_choices
      ["Monthly",
        "Quarterly",
        "Semi-annually",
        "Annually",
        "Irregular"
      ]
    end
    
    def self.data_type_choices
      ["transect","observation","data logging","remote sensing"]
    end
end
end