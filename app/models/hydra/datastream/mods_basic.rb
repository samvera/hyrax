# Datastream that uses a Generic MODS Terminology;  essentially an exemplar.
module Hydra
  module Datastream
    class ModsBasic < ActiveFedora::NokogiriDatastream       
      include Hydra::Datastream::CommonModsIndexMethods

      # MODS XML constants.
      MODS_NS = 'http://www.loc.gov/mods/v3'
      MODS_SCHEMA = 'http://www.loc.gov/standards/mods/v3/mods-3-4.xsd'

      # OM terminology
      #   this is meant to be a fairly simple MODS example.  For more complex MODS and other XML, look at the
      #   OM integration tests  https://github.com/projecthydra/om/tree/master/spec/integration
      #   and at OM documentation 
      set_terminology do |t|
        t.root(:path=>"mods", :xmlns => MODS_NS, :schema => MODS_SCHEMA)

        t.title_info(:path=>"titleInfo", :index_as => [:not_searchable]) {
          t.title
          t.subtitle(:path=>"subTitle")
        } 
        t.main_title(:proxy => [:title_info, :title])
      
        t.identifier
        t.doi(:ref=>:identifier, :attributes=>{:type=>"doi"})
        t.uri(:ref=>:identifier, :attributes=>{:type=>"uri"})
        
        t.abstract
        
        t.subject(:index_as => [:not_searchable]) {
          t.topic
        }
        t.topic_tag(:path=>"subject", :default_content_path=>"topic", :index_as=>[:facetable])

        # This is a mods:name.  The underscore is purely to avoid namespace conflicts.
        t.name_(:index_as => [:not_searchable]) {
          t.namePart(:type=>:string, :label=>"generic name")
          t.role(:ref=>[:role]) # see role below
          t.date(:path=>"namePart", :attributes=>{:type=>"date"})
          t.last_name(:path=>"namePart", :attributes=>{:type=>"family"})
          t.first_name(:path=>"namePart", :attributes=>{:type=>"given"}, :label=>"first name")
        }

        t.role(:index_as => [:not_searchable]) {
          t.text(:path=>"roleTerm",:attributes=>{:type=>"text"})
          t.code(:path=>"roleTerm",:attributes=>{:type=>"code"})
        }

        # :ref and :proxy can be used for convenience
        t.person(:ref=>:name, :attributes=>{:type=>"personal"}, :index_as=>[:facetable])
        t.organization(:ref=>:name, :attributes=>{:type=>"corporate"}, :index_as=>[:facetable])
        t.conference(:ref=>:name, :attributes=>{:type=>"conference"}, :index_as=>[:facetable])
        
      end
    
      # accessor :title, :term=>[:mods, :title_info, :main_title]
    
      # Generates an empty Mods Generic Content (used when you call ModsGenericContent.new without passing in existing xml)
      # this is necessary to create new objects
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.mods(:version=>"3.4", "xmlns:xlink"=>"http://www.w3.org/1999/xlink",
             "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
             "xmlns"=>MODS_NS,
             "xsi:schemaLocation"=>"#{MODS_NS} #{MODS_SCHEMA}") {
            xml.titleInfo(:lang=>"") {
              xml.title
            }
            xml.name(:type=>"personal") {
              xml.namePart(:type=>"given")
              xml.namePart(:type=>"family")
              xml.role {
                xml.roleTerm(:authority=>"marcrelator", :type=>"text")
              }
            }
            xml.abstract
            xml.identifier(:type=>"uri")
            xml.subject {
              xml.topic
            }
          }
        end
        return builder.doc
      end    
    
      # create a new :person node in the xml
      def insert_person
        insert_new_node(:person)
      end

      # create a new :organization node in the xml
      def insert_organization
        insert_new_node(:organization)
      end

      # create a new :conference node in the xml
      def insert_conference
        insert_new_node(:conference)
      end

    
      # FIXME: this method should probably get pushed down to OM
      # Create a new node and insert it into the document after existing term nodes, or as a child of root if no such term nodes exist
      # PREREQ:  term_template  method must exist and should return node ready for insertion into DOM
      # @param term  the symbol for an OM term with a corresponding _template method
      def insert_new_node(term)
        node = self.class.send("#{term.to_s}_template")
        nodeset = self.find_by_terms(term)
      
        unless nodeset.nil?
          if nodeset.empty?
            self.ng_xml.root.add_child(node)
            index = 0
          else
            nodeset.after(node)
            index = nodeset.length
          end
          self.dirty = true
        end
        return node, index
      end
        
      # FIXME: this method should probably get pushed down to OM
      #  a model might have a wrapping method like  remove_organization
      # Remove the node identified by the OM term and index
      # @param term  the OM term to be removed
      # @param index  the index of the OM term (e.g. the 2nd :person node)
      def remove_node(term, index)
        node = self.find_by_terms(term.to_sym => index.to_i).first
        unless node.nil?
          node.remove
          self.dirty = true
        end
      end

    
      # These templates are used when a non-trivial node needs to be added to the mods xml.  See insert_new_node above 
      
      # Generates a new :person node
      # Uses mods:name[@type="personal"]
      def self.person_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.name(:type=>"personal") {
            xml.namePart(:type=>"family")
            xml.namePart(:type=>"given")
            xml.affiliation
            xml.role {
              xml.roleTerm(:type=>"text")
            }
          }
        end
        return builder.doc.root
      end
   
      # Generates a new :organization node
      # Uses mods:name[@type="corporate"]
      def self.organization_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.name(:type=>"corporate") {
            xml.namePart
            xml.role {
              xml.roleTerm(:authority=>"marcrelator", :type=>"text")
            }                          
          }
        end
        return builder.doc.root
      end
    
      # Generates a new :conference node
      # Uses mods:name[@type="conference"]
      def self.conference_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.name(:type=>"conference") {
            xml.namePart
            xml.role {
              xml.roleTerm(:authority=>"marcrelator", :type=>"text")
            }                          
          }
        end
        return builder.doc.root
      end
    
    
      # override OM method for (FIXME: why?) some reason
      def to_solr(solr_doc=Hash.new)
        super(solr_doc)
        solr_doc.merge!(extract_person_full_names)
        solr_doc.merge!(extract_person_organizations)
        solr_doc.merge!(:object_type_facet => "Generic Mods content")
        solr_doc
      end

   
    # additional methods specific to this model
   
      # FIXME: this should move to mods behavior module and/or mods gem ?
      # these are a selected subset from   http://id.loc.gov/vocabulary/relators.html
      def self.person_relator_terms
        {"aut" => "Author",
         "clb" => "Collaborator",
         "com" => "Compiler",
         "cre" => "Creator",
         "ctb" => "Contributor",
         "edt" => "Editor",
         "ill" => "Illustrator",
         "res" => "Researcher",
         "rth" => "Research team head",
         "rtm" => "Research team member",
         "trl" => "Translator"
         }
      end
    
      # FIXME: this should move to mods behavior module and/or mods gem ?
      # these are a selected subset from   http://id.loc.gov/vocabulary/relators.html
      def self.conference_relator_terms
        {"hst" => "Host"
        }
      end
    
      # FIXME: this should move to mods behavior module and/or mods gem ?
      # these are a selected subset from   http://id.loc.gov/vocabulary/relators.html
      def self.organization_relator_terms
        {"fnd" => "Funder",
         "hst" => "Host"
        }
      end
          
    end  # class ModsBasic
  end  # module Datastream
end  # module Hydra


