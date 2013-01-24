require 'active_support/core_ext/string'
module Hydra
  module Datastream
    # Implements Hydra RightsMetadata XML terminology for asserting access permissions
    class InheritableRightsMetadata < Hydra::Datastream::RightsMetadata    
  
      @terminology = Hydra::Datastream::RightsMetadata.terminology
  
      def to_solr(solr_doc=Hash.new)
        solr_doc[ActiveFedora::SolrService.solr_name('inheritable_discover_access_group', indexer)] = discover_access.machine.group
        solr_doc[ActiveFedora::SolrService.solr_name('inheritable_discover_access_person', indexer)] = discover_access.machine.person
        solr_doc[ActiveFedora::SolrService.solr_name('inheritable_read_access_group', indexer)] = read_access.machine.group
        solr_doc[ActiveFedora::SolrService.solr_name('inheritable_read_access_person', indexer)] = read_access.machine.person
        solr_doc[ActiveFedora::SolrService.solr_name('inheritable_edit_access_group', indexer)] = edit_access.machine.group
        solr_doc[ActiveFedora::SolrService.solr_name('inheritable_edit_access_person', indexer)] = edit_access.machine.person
        solr_doc[ActiveFedora::SolrService.solr_name('inheritable_embargo_release_date', date_indexer)] = embargo_release_date
        return solr_doc
      end
    end
  end
end
