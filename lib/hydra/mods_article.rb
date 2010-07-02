module Hydra
class ModsArticle < ActiveFedora::NokogiriDatastream       
  
    # have to call this in order to set namespace & schema
    root_property :mods, "mods", "http://www.loc.gov/mods/v3", :attributes=>["id", "version"], :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"          
                
    property :title_info, :path=>"titleInfo", 
                :convenience_methods => {
                  :main_title => {:path=>"title"},
                  :language => {:path=>{:attribute=>"lang"}},                    
                }
    property :abstract, :path=>"abstract"
    property :topic_tag, :path=>'subject',:default_content_path => "topic"
    
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
                
    property :person, :variant_of=>:name_, :attributes=>{:type=>"personal"}
    property :organizaton, :variant_of=>:name_, :attributes=>{:type=>"institutional"}
    property :conference, :variant_of=>:name_, :attributes=>{:type=>"conference"}
    
    property :role, :path=>"role",
                :parents=>[:name_],
                :convenience_methods => {
                  :text => {:path=>"roleTerm", :attributes=>{:type=>"text"}},
                  :code => {:path=>"roleTerm", :attributes=>{:type=>"code"}},                    
                }
                
    property :journal, :path=>'relatedItem', :attributes=>{:type=>"host"},
                :subelements=>[:title_info, :origin_info, :issue],
                :convenience_methods => {
                  :issn => {:path=>"identifier", :attributes=>{:type=>"issn"}},
                }
    
    property :origin_info, :path=>'originInfo',
                :subelements=>["publisher","dateIssued"]
                
    property :issue, :path=>'part',
                :subelements=>[:start_page, :end_page],
                :convenience_methods => {
                  :volume => {:path=>"detail", :attributes=>{:type=>"volume"}},
                  :level => {:path=>"detail", :attributes=>{:type=>"level"}},
                  # Hack to support provisional spot for start & end page (nesting was too deep for this version of OM)
                  :citation_start_page => {:path=>"pages", :attributes=>{:type=>"start"}},
                  :citation_end_page => {:path=>"pages", :attributes=>{:type=>"end"}},
                  :foo => {:path=>"foo", :attributes=>{:type=>"ness"}},
                  :publication_date => {:path=>"date"}
                }

    # Correct usage of Start & End pages...
    property :start_page, :path=>"extent", :attributes=>{:unit=>"pages"}, :default_content_path => "start"
    property :end_page, :path=>"extent", :attributes=>{:unit=>"pages"}, :default_content_path => "end"
                
    generate_accessors_from_properties      
    
end
end