module Hydra
  module ModelMixins
    module RightsMetadata
      extend ActiveSupport::Concern
      extend Deprecation
      include Hydra::AccessControls::Permissions

      included do
        Deprecation.warn(RightsMetadata, "Hydra::ModelMixins::RightsMetadata has been deprecated and will be removed in hydra-head 7.0. Use Hydra::AccessControls::Permissions instead", caller(3));
      end

      ## Returns a list with all the permissions on the object.
      # @example
      #  [{:name=>"group1", :access=>"discover", :type=>'group'},
      #  {:name=>"group2", :access=>"discover", :type=>'group'},
      #  {:name=>"user2", :access=>"read", :type=>'user'},
      #  {:name=>"user1", :access=>"edit", :type=>'user'},
      #  {:name=>"user3", :access=>"read", :type=>'user'}]
      def permissions
        (rightsMetadata.groups.map {|x| {:type=>'group', :access=>x[1], :name=>x[0] }} + 
          rightsMetadata.individuals.map {|x| {:type=>'user', :access=>x[1], :name=>x[0]}})

      end
    
    end
  end
end
