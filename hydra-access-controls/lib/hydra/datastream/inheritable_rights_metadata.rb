require 'active_support/core_ext/string'
module Hydra
  module Datastream
    # Implements Hydra RightsMetadata XML terminology for asserting access permissions
    class InheritableRightsMetadata < Hydra::Datastream::RightsMetadata    
  
      @terminology = Hydra::Datastream::RightsMetadata.terminology
  
      def to_solr(solr_doc=Hash.new)
        solr_doc["inheritable_access_t"] = access.machine.group.val + access.machine.person.val
        solr_doc["inheritable_discover_access_group_t"] = discover_access.machine.group
        solr_doc["inheritable_discover_access_person_t"] = discover_access.machine.person
        solr_doc["inheritable_read_access_group_t"] = read_access.machine.group
        solr_doc["inheritable_read_access_person_t"] = read_access.machine.person
        solr_doc["inheritable_edit_access_group_t"] = edit_access.machine.group
        solr_doc["inheritable_edit_access_person_t"] = edit_access.machine.person
        solr_doc["inheritable_embargo_release_date_dt"] = embargo_release_date
        return solr_doc
      end
    end
  end
end