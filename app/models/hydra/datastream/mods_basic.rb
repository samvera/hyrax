# Datastream that uses a Generic MODS Terminology;  essentially an exemplar.
module Hydra
  module Datastream
    class ModsBasic < ActiveFedora::NokogiriDatastream       
      include Hydra::Datastream::CommonModsIndexMethods

      # MODS XML constants.
      MODS_NS = 'http://www.loc.gov/mods/v3'
      MODS_SCHEMA = 'http://www.loc.gov/standards/mods/v3/mods-3-3.xsd'

      # OM terminology
      #   this is meant to be a fairly simple MODS example.  For more complex MODS and other XML, look at the
      #   OM integration tests  https://github.com/projecthydra/om/tree/master/spec/integration
      #   and at OM documentation 
      set_terminology do |t|
        t.root(:path=>"mods", :xmlns => MODS_NS, :schema => MODS_SCHEMA)

        t.title_info(:path=>"titleInfo", :index_as => [:not_searchable]) {
          t.title(:label=>"title")
          t.subtitle(:path=>"subTitle")
        } 
        t.main_title(:proxy => [:title_info, :title])
      
        t.identifier
        t.doi(:ref=>:identifier, :attributes=>{:type=>"doi"})
        t.uri(:ref=>:identifier, :attributes=>{:type=>"uri"})
        
        t.abstract   
        
        t.subject :index_as => [:not_searchable] {
          t.topic
        }      
        t.topic_tag(:path=>"subject", :default_content_path=>"topic", :index_as=>[:facetable])

        # This is a mods:name.  The underscore is purely to avoid namespace conflicts.
        t.name_ :index_as => [:not_searchable] {
          t.namePart(:type=>:string, :label=>"generic name")
          t.role(:ref=>[:role]) # see role below
          t.date(:path=>"namePart", :attributes=>{:type=>"date"})
          t.last_name(:path=>"namePart", :attributes=>{:type=>"family"})
          t.first_name(:path=>"namePart", :attributes=>{:type=>"given"}, :label=>"first name")
        }

        t.role :index_as => [:not_searchable] {
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
          xml.mods(:version=>"3.3", "xmlns:xlink"=>"http://www.w3.org/1999/xlink",
             "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
             "xmlns"=>MODS_NS,
             "xsi:schemaLocation"=>"#{MODS_NS} #{MODS_SCHEMA}") {
            xml.titleInfo(:lang=>"") {
              xml.title
            }
            xml.name(:type=>"personal") {
              xml.namePart(:type=>"given")
              xml.namePart(:type=>"family")
              xml.affiliation
              xml.role {
                xml.roleTerm(:authority=>"marcrelator", :type=>"text")
              }
            }
            xml.typeOfResource
            xml.genre(:authority=>"marcgt")
            xml.language {
              xml.languageTerm(:authority=>"iso639-2b", :type=>"code")
            }
            # mods:physicaldescription/mods:extent - used for storing file size in human-readable form.
            xml.physicalDescription {
              xml.extent
            }
            xml.abstract
            xml.subject {
              xml.topic
            }
            xml.relatedItem(:type=>"host") {
              xml.titleInfo {
                xml.title
              }
              xml.identifier(:type=>"issn")
              xml.originInfo {
                xml.publisher
                xml.dateIssued
              }
              xml.part {
                xml.detail(:type=>"volume") {
                  xml.number
                }
                xml.detail(:type=>"number") {
                  xml.number
                }
                xml.extent(:unit=>"pages") {
                  xml.start
                  xml.end
                }
                xml.date
              }
            }
            xml.location {
              xml.url
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
    
      # FIXME: this should move to mods behavior module and/or mods gem ?
      # these are from   http://id.loc.gov/vocabulary/relators.html
      def self.dc_relator_terms
         {"acp" => "Art copyist",
          "act" => "Actor",
          "adp" => "Adapter",
          "aft" => "Author of afterword, colophon, etc.",
          "anl" => "Analyst",
          "anm" => "Animator",
          "ann" => "Annotator",
          "ant" => "Bibliographic antecedent",
          "app" => "Applicant",
          "aqt" => "Author in quotations or text abstracts",
          "arc" => "Architect",
          "ard" => "Artistic director ",
          "arr" => "Arranger",
          "art" => "Artist",
          "asg" => "Assignee",
          "asn" => "Associated name",
          "att" => "Attributed name",
          "auc" => "Auctioneer",
          "aud" => "Author of dialog",
          "aui" => "Author of introduction",
          "aus" => "Author of screenplay",
          "aut" => "Author",
          "bdd" => "Binding designer",
          "bjd" => "Bookjacket designer",
          "bkd" => "Book designer",
          "bkp" => "Book producer",
          "bnd" => "Binder",
          "bpd" => "Bookplate designer",
          "bsl" => "Bookseller",
          "ccp" => "Conceptor",
          "chr" => "Choreographer",
          "clb" => "Collaborator",
          "cli" => "Client",
          "cll" => "Calligrapher",
          "clt" => "Collotyper",
          "cmm" => "Commentator",
          "cmp" => "Composer",
          "cmt" => "Compositor",
          "cng" => "Cinematographer",
          "cnd" => "Conductor",
          "cns" => "Censor",
          "coe" => "Contestant -appellee",
          "col" => "Collector",
          "com" => "Compiler",
          "cos" => "Contestant",
          "cot" => "Contestant -appellant",
          "cov" => "Cover designer",
          "cpc" => "Copyright claimant",
          "cpe" => "Complainant-appellee",
          "cph" => "Copyright holder",
          "cpl" => "Complainant",
          "cpt" => "Complainant-appellant",
          "cre" => "Creator",
          "crp" => "Correspondent",
          "crr" => "Corrector",
          "csl" => "Consultant",
          "csp" => "Consultant to a project",
          "cst" => "Costume designer",
          "ctb" => "Contributor",
          "cte" => "Contestee-appellee",
          "ctg" => "Cartographer",
          "ctr" => "Contractor",
          "cts" => "Contestee",
          "ctt" => "Contestee-appellant",
          "cur" => "Curator",
          "cwt" => "Commentator for written text",
          "dfd" => "Defendant",
          "dfe" => "Defendant-appellee",
          "dft" => "Defendant-appellant",
          "dgg" => "Degree grantor",
          "dis" => "Dissertant",
          "dln" => "Delineator",
          "dnc" => "Dancer",
          "dnr" => "Donor",
          "dpc" => "Depicted",
          "dpt" => "Depositor",
          "drm" => "Draftsman",
          "drt" => "Director",
          "dsr" => "Designer",
          "dst" => "Distributor",
          "dtc" => "Data contributor ",
          "dte" => "Dedicatee",
          "dtm" => "Data manager ",
          "dto" => "Dedicator",
          "dub" => "Dubious author",
          "edt" => "Editor",
          "egr" => "Engraver",
          "elg" => "Electrician ",
          "elt" => "Electrotyper",
          "eng" => "Engineer",
          "etr" => "Etcher",
          "exp" => "Expert",
          "fac" => "Facsimilist",
          "fld" => "Field director ",
          "flm" => "Film editor",
          "fmo" => "Former owner",
          "fpy" => "First party",
          "fnd" => "Funder",
          "frg" => "Forger",
          "gis" => "Geographic information specialist ",
          "grt" => "Graphic technician",
          "hnr" => "Honoree",
          "hst" => "Host",
          "ill" => "Illustrator",
          "ilu" => "Illuminator",
          "ins" => "Inscriber",
          "inv" => "Inventor",
          "itr" => "Instrumentalist",
          "ive" => "Interviewee",
          "ivr" => "Interviewer",
          "lbr" => "Laboratory ",
          "lbt" => "Librettist",
          "ldr" => "Laboratory director ",
          "led" => "Lead",
          "lee" => "Libelee-appellee",
          "lel" => "Libelee",
          "len" => "Lender",
          "let" => "Libelee-appellant",
          "lgd" => "Lighting designer",
          "lie" => "Libelant-appellee",
          "lil" => "Libelant",
          "lit" => "Libelant-appellant",
          "lsa" => "Landscape architect",
          "lse" => "Licensee",
          "lso" => "Licensor",
          "ltg" => "Lithographer",
          "lyr" => "Lyricist",
          "mcp" => "Music copyist",
          "mfr" => "Manufacturer",
          "mdc" => "Metadata contact",
          "mod" => "Moderator",
          "mon" => "Monitor",
          "mrk" => "Markup editor",
          "msd" => "Musical director",
          "mte" => "Metal-engraver",
          "mus" => "Musician",
          "nrt" => "Narrator",
          "opn" => "Opponent",
          "org" => "Originator",
          "orm" => "Organizer of meeting",
          "oth" => "Other",
          "own" => "Owner",
          "pat" => "Patron",
          "pbd" => "Publishing director",
          "pbl" => "Publisher",
          "pdr" => "Project director",
          "pfr" => "Proofreader",
          "pht" => "Photographer",
          "plt" => "Platemaker",
          "pma" => "Permitting agency",
          "pmn" => "Production manager",
          "pop" => "Printer of plates",
          "ppm" => "Papermaker",
          "ppt" => "Puppeteer",
          "prc" => "Process contact",
          "prd" => "Production personnel",
          "prf" => "Performer",
          "prg" => "Programmer",
          "prm" => "Printmaker",
          "pro" => "Producer",
          "prt" => "Printer",
          "pta" => "Patent applicant",
          "pte" => "Plaintiff -appellee",
          "ptf" => "Plaintiff",
          "pth" => "Patent holder",
          "ptt" => "Plaintiff-appellant",
          "rbr" => "Rubricator",
          "rce" => "Recording engineer",
          "rcp" => "Recipient",
          "red" => "Redactor",
          "ren" => "Renderer",
          "res" => "Researcher",
          "rev" => "Reviewer",
          "rps" => "Repository",
          "rpt" => "Reporter",
          "rpy" => "Responsible party",
          "rse" => "Respondent-appellee",
          "rsg" => "Restager",
          "rsp" => "Respondent",
          "rst" => "Respondent-appellant",
          "rth" => "Research team head",
          "rtm" => "Research team member",
          "sad" => "Scientific advisor",
          "sce" => "Scenarist",
          "scl" => "Sculptor",
          "scr" => "Scribe",
          "sds" => "Sound designer",
          "sec" => "Secretary",
          "sgn" => "Signer",
          "sht" => "Supporting host",
          "sng" => "Singer",
          "spk" => "Speaker",
          "spn" => "Sponsor",
          "spy" => "Second party",
          "srv" => "Surveyor",
          "std" => "Set designer",
          "stl" => "Storyteller",
          "stm" => "Stage manager",
          "stn" => "Standards body",
          "str" => "Stereotyper",
          "tcd" => "Technical director",
          "tch" => "Teacher",
          "ths" => "Thesis advisor",
          "trc" => "Transcriber",
          "trl" => "Translator",
          "tyd" => "Type designer",
          "tyg" => "Typographer",
          "vdg" => "Videographer",
          "voc" => "Vocalist",
          "wam" => "Writer of accompanying material",
          "wdc" => "Woodcutter",
          "wde" => "Wood-engraver",
          "wit" => "Witness"}
        end
      
    end  # class ModsBasic
  end  # module Datastream
end  # module Hydra


