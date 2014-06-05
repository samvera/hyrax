require 'active_support/core_ext/string'
module Hydra
  module Datastream
    # Implements Hydra RightsMetadata XML terminology for asserting access permissions
    class InheritableRightsMetadata < Hydra::Datastream::RightsMetadata    
  
      @terminology = Hydra::Datastream::RightsMetadata.terminology
  
      def to_solr(solr_doc=Hash.new)
        [:discover, :read, :edit].each do |access|
          solr_doc[Hydra.config[:permissions][:inheritable][access][:group]] = send("#{access}_access").machine.group
          solr_doc[Hydra.config[:permissions][:inheritable][access][:individual]] = send("#{access}_access").machine.person
        end
        if embargo_release_date.present?
          key = Hydra.config.permissions.inheritable.embargo.release_date.sub(/_[^_]+$/, '') #Strip off the suffix
          ::Solrizer.insert_field(solr_doc, key, embargo_release_date, :stored_sortable)
        end
        return solr_doc
      end
    end
  end
end
