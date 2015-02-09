require 'active_support/core_ext/string'
module Hydra
  module Datastream
    # Implements Hydra RightsMetadata XML terminology for asserting access permissions
    class RightsMetadata < ActiveFedora::OmDatastream       
      
      set_terminology do |t|
        t.root(:path=>"rightsMetadata", :xmlns=>"http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1", :schema=>"http://github.com/projecthydra/schemas/tree/v1/rightsMetadata.xsd") 
        t.copyright {
          ## BEGIN possible delete, justin 2012-06-22
          t.machine {
            t.cclicense   
            t.license     
          }
          t.human_readable(:path=>"human")
          t.license(:proxy=>[:machine, :license ])            
          t.cclicense(:proxy=>[:machine, :cclicense ])                  
          ## END possible delete

          t.title(:path=>'human', :attributes=>{:type=>'title'})
          t.description(:path=>'human', :attributes=>{:type=>'description'})
          t.url(:path=>'machine', :attributes=>{:type=>'uri'})
        }
        t.access do
          t.human_readable(:path=>"human")
          t.machine {
            t.group
            t.person
          }
          t.person(:proxy=>[:machine, :person])
          t.group(:proxy=>[:machine, :group])
          # accessor :access_person, :term=>[:access, :machine, :person]
        end
        t.discover_access(:ref=>[:access], :attributes=>{:type=>"discover"})
        t.read_access(:ref=>[:access], :attributes=>{:type=>"read"})
        t.edit_access(:ref=>[:access], :attributes=>{:type=>"edit"})
        # A bug in OM prevnts us from declaring proxy terms at the root of a Terminology
        # t.access_person(:proxy=>[:access,:machine,:person])
        # t.access_group(:proxy=>[:access,:machine,:group])
        
        t.embargo {
          t.human_readable(path: "human")
          t.machine{
            t.date(type: :time, attributes: {type: "release"})
            t.date_deactivated(type: "deactivated")
            t.visibility_during(path: "visibility", attributes: {scope: 'during'})
            t.visibility_after(path: "visibility", attributes: {scope: 'after'})
          }
        }

        t.lease {
          t.human_readable(path: "human")
          t.machine{
            t.date(type: :time, attributes: {type: "expire"})
            t.date_deactivated(type: :time, attributes: {type: "deactivated"})
            t.visibility_during(path: "visibility", attributes: {scope: 'during'})
            t.visibility_after(path: "visibility", attributes: {scope: 'after'})
          }
        }

        t.license(:ref=>[:copyright])

        t.visibility_during_embargo proxy: [:embargo, :machine, :visibility_during]
        t.visibility_after_embargo proxy: [:embargo, :machine, :visibility_after]
        t.visibility_during_lease proxy: [:lease, :machine, :visibility_during]
        t.visibility_after_lease proxy: [:lease, :machine, :visibility_after]
        t.embargo_history proxy: [:embargo, :human_readable]
        t.lease_history proxy: [:lease, :human_readable]
        t.embargo_release_date proxy: [:embargo, :machine, :date], type: :time
        t.embargo_deactivation_date proxy: [:embargo, :machine, :date_deactivated]
        t.lease_expiration_date proxy: [:lease, :machine, :date], type: :time
        t.lease_deactivation_date proxy: [:lease, :machine, :date_deactivated]

      end

      # Generates an empty Mods Article (used when you call ModsArticle.new without passing in existing xml)
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.rightsMetadata(:version=>"0.1", "xmlns"=>"http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1") {
            xml.copyright {
              xml.human(:type=>'title')
              xml.human(:type=>'description')
              xml.machine(:type=>'uri')
              
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
            xml.embargo{
              xml.machine
            }
            xml.lease{
              xml.machine
            }
          }
        end
        return builder.doc
      end
        
      # Returns the permissions for the selected person/group
      # If new_access_level is provided, updates the selected person/group access_level to the one specified 
      # A new_access_level of "none" will remove all access_levels for the selected person/group
      # @param [Hash] selector hash in format {type => identifier}
      # @param new_access_level (default nil)
      # @return Hash in format {type => access_level}.  
      # 
      # ie. 
      # permissions({:person=>"person123"})
      # => {"person123"=>"edit"}
      # permissions({:person=>"person123"}, "read")
      # => {"person123"=>"read"}
      # permissions({:person=>"person123"})
      # => {"person123"=>"read"}
      def permissions(selector, new_access_level=nil)
        type = selector.keys.first.to_sym
        actor = selector.values.first
        if new_access_level.nil?
          xpath = xpath(type, actor)
          nodeset = self.find_by_terms(xpath)
          if nodeset.empty?
            return "none"
          else
            return nodeset.first.ancestors("access").first.attributes["type"].text
          end
        else
          remove_all_permissions(selector)
          if new_access_level == "none" 
            self.content = self.to_xml
          else
            access_type_symbol = "#{new_access_level}_access".to_sym
            current_values = term_values(access_type_symbol, type)
            self.update_values([access_type_symbol, type] => current_values + [actor] )
          end
          return new_access_level
        end
          
      end
      
      # Reports on which groups have which permissions
      # @return Hash in format {group_name => group_permissions, group_name => group_permissions}
      def groups
        return quick_search_by_type(:group)
      end
      
      # Reports on which users have which permissions
      # @return Hash in format {user_name => user_permissions, user_name => user_permissions}
      def users
        return quick_search_by_type(:person)
      end
      
      # Updates permissions for all of the persons and groups in a hash
      # @param params ex. {"group"=>{"group1"=>"discover","group2"=>"edit"}, "person"=>{"person1"=>"read","person2"=>"discover"}}
      # Currently restricts actor type to group or person.  Any others will be ignored
      def update_permissions(params)
        params.fetch("group", {}).each_pair {|group_id, access_level| self.permissions({"group"=>group_id}, access_level)}
        params.fetch("person", {}).each_pair {|person_id, access_level| self.permissions({"person"=>person_id}, access_level)}
      end

      # Updates all permissions
      # @param params ex. {"group"=>{"group1"=>"discover","group2"=>"edit"}, "person"=>{"person1"=>"read","person2"=>"discover"}}
      # Restricts actor type to group or person.  Any others will be ignored
      def permissions= (params)
        groups_for_update = params['group'] ? params['group'].keys : []
        group_ids = groups.keys | groups_for_update
        group_ids.each {|group_id| self.permissions({"group"=>group_id}, params['group'].fetch(group_id, 'none'))}
        users_for_update = params['person'] ? params['person'].keys : []
        user_ids = users.keys | users_for_update
        user_ids.each {|person_id| self.permissions({"person"=>person_id}, params['person'].fetch(person_id, 'none'))}
      end
      
      # @param [Symbol] type (either :group or :person)
      # @return 
      # This method limits the response to known access levels.  Probably runs a bit faster than .permissions().
      def quick_search_by_type(type)
        result = {}
        [{:discover_access=>"discover"},{:read_access=>"read"},{:edit_access=>"edit"}].each do |access_levels_hash|
          access_level = access_levels_hash.keys.first
          access_level_name = access_levels_hash.values.first
          self.find_by_terms(*[access_level, type]).each do |entry|
            result[entry.text] = access_level_name
          end
        end
        return result
      end

      def under_embargo?
        (embargo_release_date.present? && Date.today < embargo_release_date.first) ? true : false
      end

      def active_lease?
        lease_expiration_date.present? && Date.today < lease_expiration_date.first
      end

      def to_solr(solr_doc=Hash.new)
        [:discover, :read, :edit].each do |access|
          vals = send("#{access}_access").machine.group
          solr_doc[Hydra.config.permissions[access].group] = vals unless vals.empty?
          vals = send("#{access}_access").machine.person
          solr_doc[Hydra.config.permissions[access].individual] = vals unless vals.empty?
        end
        if embargo_release_date.present?
          key = Hydra.config.permissions.embargo.release_date.sub(/_[^_]+$/, '') #Strip off the suffix
          ::Solrizer.insert_field(solr_doc, key, embargo_release_date, :stored_sortable)
        end
        if lease_expiration_date.present?
          key = Hydra.config.permissions.lease.expiration_date.sub(/_[^_]+$/, '') #Strip off the suffix
          ::Solrizer.insert_field(solr_doc, key, lease_expiration_date, :stored_sortable)
        end
        solr_doc[::Solrizer.solr_name("visibility_during_embargo", :symbol)] = visibility_during_embargo unless visibility_during_embargo.nil?
        solr_doc[::Solrizer.solr_name("visibility_after_embargo", :symbol)] = visibility_after_embargo unless visibility_after_embargo.nil?
        solr_doc[::Solrizer.solr_name("visibility_during_lease", :symbol)] = visibility_during_lease unless visibility_during_lease.nil?
        solr_doc[::Solrizer.solr_name("visibility_after_lease", :symbol)] = visibility_after_lease unless visibility_after_lease.nil?
        solr_doc[::Solrizer.solr_name("embargo_history", :symbol)] = embargo_history unless embargo_history.nil?
        solr_doc[::Solrizer.solr_name("lease_history", :symbol)] = lease_history unless lease_history.nil?
        solr_doc
      end

      def indexer
        self.class.indexer
      end

      def self.indexer
        @indexer ||= Solrizer::Descriptor.new(:string, :stored, :indexed, :multivalued)
      end

      def date_indexer
        self.class.date_indexer
      end

      def self.date_indexer
        @date_indexer ||= Solrizer::Descriptor.new(:date, :stored, :indexed)
      end

      # Completely clear the permissions
      def clear_permissions!
        remove_all_permissions({:person=>true})
        remove_all_permissions({:group=>true})
      end


      
      private
      # Purge all access given group/person 
      def remove_all_permissions(selector)
        return unless ng_xml
        type = selector.keys.first.to_sym
        actor = selector.values.first
        xpath = xpath(type, actor)
        nodes_to_purge = self.find_by_terms(xpath)
        nodes_to_purge.each {|node| node.remove}
      end

      # @param [Symbol] type (:group, :person)
      # @param [String,TrueClass] actor the user we want to find. If actor is true, then don't query.
      def xpath(type, actor)
        raise ArgumentError, "Type must either be ':group' or ':person'. You provided: '#{type.inspect}'" unless [:group, :person].include?(type)
        path = "//oxns:access/oxns:machine/oxns:#{type}"
        if actor.is_a? String
          clean_actor = actor.gsub("'", '')
          path += "[text() = '#{clean_actor}']" 
        end
        path
      end
      
    end
  end
end
