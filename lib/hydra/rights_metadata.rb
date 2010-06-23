module Hydra
class RightsMetadata < ActiveFedora::NokogiriDatastream       
  
    # have to call this in order to set namespace & schema
    root_property :rightsMetadata, "rightsMetadata", "http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1", :schema=>"http://github.com/projecthydra/schemas/tree/v1/rightsMetadata.xsd"          
    
    accessor :access_group, :relative_xpath=>'access/machine/group'
    accessor :access_person, :relative_xpath=>'access/machine/person'
        
    accessor :discover_access, :relative_xpath=>'access[@type="discover"]', :children=>[
      {:human_readable=>{:relative_xpath=>'human'}},
      {:group=>{:relative_xpath=>'machine/group'}},  
      {:person=>{:relative_xpath=>'machine/person'}}       
    ]
    accessor :read_access, :relative_xpath=>'access[@type="read"]', :children=>[
      {:human_readable=>{:relative_xpath=>'human'}},
      {:group=>{:relative_xpath=>'machine/group'}},  
      {:person=>{:relative_xpath=>'machine/person'}}       
    ]
    accessor :edit_access, :relative_xpath=>'access[@type="edit"]', :children=>[
      {:human_readable=>{:relative_xpath=>'human'}},
      {:group=>{:relative_xpath=>'machine/group'}},  
      {:person=>{:relative_xpath=>'machine/person'}}       
    ]
    accessor :copyright, :relative_xpath=>'copyright', :children=>[
      {:human_readable=>{:relative_xpath=>'human'}},
      {:machine_readable=>{:relative_xpath=>'machine'}}
    ]
  
end
end