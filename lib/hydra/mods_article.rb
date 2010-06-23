module Hydra
class ModsArticle < ActiveFedora::NokogiriDatastream       
  
    # have to call this in order to set namespace & schema
    root_property :mods, "mods", "http://www.loc.gov/mods/v3", :attributes=>["id", "version"], :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"          
    
    accessor :title_info, :relative_xpath=>'oxns:titleInfo', :children=>[
      {:main_title=>{:relative_xpath=>'oxns:title'}},         
      {:language =>{:relative_xpath=>{:attribute=>"lang"} }}
      ] 
    accessor :abstract
    accessor :topic_tag, :relative_xpath=>'oxns:subject/oxns:topic'
    accessor :person, :relative_xpath=>'oxns:name[@type="personal"]',  :children=>[
      {:last_name=>{:relative_xpath=>'oxns:namePart[@type="family"]'}}, 
      {:first_name=>{:relative_xpath=>'oxns:namePart[@type="given"]'}}, 
      {:institution=>{:relative_xpath=>'oxns:affiliation'}}, 
      {:role=>{:children=>[
        {:text=>{:relative_xpath=>'oxns:roleTerm[@type="text"]'}},
        {:code=>{:relative_xpath=>'oxns:roleTerm[@type="code"]'}}
      ]}}
    ]
    accessor :organization, :relative_xpath=>'oxns:name[@type="institutional"]', :children=>[
      {:role=>{:children=>[
        {:text=>{:relative_xpath=>'oxns:roleTerm[@type="text"]'}},
        {:code=>{:relative_xpath=>'oxns:roleTerm[@type="code"]'}}
      ]}}
    ]
    accessor :conference, :relative_xpath=>'oxns:name[@type="conference"]', :children=>[
      {:role=>{:children=>[
        {:text=>{:relative_xpath=>'oxns:roleTerm[@type="text"]'}},
        {:code=>{:relative_xpath=>'oxns:roleTerm[@type="code"]'}}
      ]}}
    ]
    accessor :journal, :relative_xpath=>'oxns:relatedItem[@type="host"]', :children=>[
        {:title=>{:relative_xpath=>'oxns:titleInfo/oxns:title'}}, 
        {:publisher=>{:relative_xpath=>'oxns:originInfo/oxns:publisher'}},
        {:issn=>{:relative_xpath=>'oxns:identifier[@type="issn"]'}}, 
        {:date_issued=>{:relative_xpath=>'oxns:originInfo/oxns:dateIssued'}},
        {:issue => {:relative_xpath=>"oxns:part", :children=>[
          {:volume=>{:relative_xpath=>'oxns:detail[@type="volume"]'}},
          {:level=>{:relative_xpath=>'oxns:detail[@type="level"]'}},
          {:start_page=>{:relative_xpath=>'oxns:extent[@unit="pages"]/oxns:start'}},
          {:end_page=>{:relative_xpath=>'oxns:extent[@unit="pages"]/oxns:end'}},
          {:publication_date=>{:relative_xpath=>'oxns:date'}}
        ]}}
    ]    
  
end
end