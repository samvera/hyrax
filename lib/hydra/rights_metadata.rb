module Hydra
class RightsMetadata < ActiveFedora::NokogiriDatastream       
  
    # have to call this in order to set namespace & schema
    root_property :rightsMetadata, "rightsMetadata", "http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1", :schema=>"http://github.com/projecthydra/schemas/tree/v1/rightsMetadata.xsd"          
    
    property :name_, :path=>"name", 
                :attributes=>[:xlink, :lang, "xml:lang", :script, :transliteration, {:type=>["personal", "enumerated", "corporate"]} ],
                :subelements=>["namePart", "displayForm", "affiliation", :role, "description"],
                :default_content_path => "namePart",
                :convenience_methods => {
                  :date => {:path=>"namePart", :attributes=>{:type=>"date"}},
                  :last_name => {:path=>"namePart", :attributes=>{:type=>"family"}},
                  :first_name => {:path=>"namePart", :attributes=>{:type=>"given"}},
                  :terms_of_address => {:path=>"namePart", :attributes=>{:type=>"termsOfAddress"}},
                  :institution=>{:path=>'affiliation'}
                }
    
    property :copyright, :path=>"copyright",
                :subelements=>["machine"],
                :convenience_methods => {
                  :human_readable => {:path=>"human"}
                }
                    
    property :access, :path=>"access",
                :subelements=>[:machine],
                :convenience_methods => {
                  :human_readable => {:path=>"human"},
                  :group => {:path=>"group"},
                  :person => {:path=>"person"}
                }
    property :discover_access, :variant_of=>:access, :attributes=>{:type=>"discover"}
    property :read_access, :variant_of=>:access, :attributes=>{:type=>"read"}
    property :edit_access, :variant_of=>:access, :attributes=>{:type=>"edit"}
    
    # property :machine, :path=>"machine",
    #             :subelements=>["group","person"]
                
    generate_accessors_from_properties
    
    accessor :access_group, :relative_xpath=>'access/machine/group'
    accessor :access_person, :relative_xpath=>'access/machine/person'
    
    # Generates an empty Mods Article (used when you call ModsArticle.new without passing in existing xml)
    def self.xml_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.rightsMetadata(:version=>"0.1", "xmlns"=>"http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1") {
          xml.copyright {
            xml.human
          }
          xml.access(:type=>"discover") {
            xml.human
            xml.machine
          }
          xml.access(:type=>"read") {
            xml.human
            xml.machine
          }
          xml.access(:type=>"edit") {
            xml.human
            xml.machine
          }
        }
      end
      return builder.doc
    end

    #   
    # accessor :discover_access, :relative_xpath=>'access[@type="discover"]', :children=>[
    #   {:human_readable=>{:relative_xpath=>'human'}},
    #   {:group=>{:relative_xpath=>'machine/group'}},  
    #   {:person=>{:relative_xpath=>'machine/person'}}       
    # ]
    # accessor :read_access, :relative_xpath=>'access[@type="read"]', :children=>[
    #   {:human_readable=>{:relative_xpath=>'human'}},
    #   {:group=>{:relative_xpath=>'machine/group'}},  
    #   {:person=>{:relative_xpath=>'machine/person'}}       
    # ]
    # accessor :edit_access, :relative_xpath=>'access[@type="edit"]', :children=>[
    #   {:human_readable=>{:relative_xpath=>'human'}},
    #   {:group=>{:relative_xpath=>'machine/group'}},  
    #   {:person=>{:relative_xpath=>'machine/person'}}       
    # ]
    # accessor :copyright, :relative_xpath=>'copyright', :children=>[
    #   {:human_readable=>{:relative_xpath=>'human'}},
    #   {:machine_readable=>{:relative_xpath=>'machine'}}
    # ]
  
end
end