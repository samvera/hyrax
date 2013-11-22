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
        solr_doc[Hydra.config[:permissions][:inheritable][:embargo_release_date]] = embargo_release_date
        return solr_doc
      end
    end
  end
end
