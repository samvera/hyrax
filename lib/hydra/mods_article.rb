module Hydra
class ModsArticle < ActiveFedora::NokogiriDatastream       
  
    # have to call this in order to set namespace & schema
    root_property :mods, "mods", "http://www.loc.gov/mods/v3", :attributes=>["id", "version"], :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"          
                
    property :title_info, :path=>"titleInfo", 
                :convenience_methods => {
                  :main_title => {:path=>"title"},
                  # :language => {:path=>{:attribute=>"lang"}},    
                  :language => {:path=>"language"},                 
                }
    property :abstract, :path=>"abstract"
    property :subject, :path=>'subject',:subelements => "topic"    
    property :name_, :path=>"name", 
                :attributes=>[:xlink, :lang, "xml:lang", :script, :transliteration, {:type=>["personal", "enumerated", "corporate"]} ],
                :subelements=>["namePart", "displayForm", "affiliation", :role, "description"],
                :default_content_path => "namePart",
                :convenience_methods => {
                  :date => {:path=>"namePart", :attributes=>{:type=>"date"}},
                  :last_name => {:path=>"namePart", :attributes=>{:type=>"family"}},
                  :first_name => {:path=>"namePart", :attributes=>{:type=>"given"}},
                  :terms_of_address => {:path=>"namePart", :attributes=>{:type=>"termsOfAddress"}},
                  :institution=>{:path=>'affiliation'}
                }
                
    property :person, :variant_of=>:name_, :attributes=>{:type=>"personal"}
    property :organization, :variant_of=>:name_, :attributes=>{:type=>"corporate"}
    property :conference, :variant_of=>:name_, :attributes=>{:type=>"conference"}
    
    property :role, :path=>"role",
                :parents=>[:name_],
                :convenience_methods => {
                  :text => {:path=>"roleTerm", :attributes=>{:type=>"text"}},
                  :code => {:path=>"roleTerm", :attributes=>{:type=>"code"}},                    
                }
                
    property :journal, :path=>'relatedItem', :attributes=>{:type=>"host"},
                :subelements=>[:title_info, :origin_info, :issue],
                :convenience_methods => {
                  :issn => {:path=>"identifier", :attributes=>{:type=>"issn"}},
                }
    
    property :origin_info, :path=>'originInfo',
                :subelements=>["publisher","dateIssued"]
                
    property :issue, :path=>'part',
                # :subelements=>[:start_page, :end_page, :volume, :level],
                :convenience_methods => {
                  # Hacks to support provisional spot for start & end page, etc (nesting was too deep for this version of OM)
                  :volume => {:path=>"detail", :attributes=>{:type=>"volume"}},
                  :level => {:path=>"detail", :attributes=>{:type=>"number"}},
                  :start_page => {:path=>"pages", :attributes=>{:type=>"start"}},
                  :end_page => {:path=>"pages", :attributes=>{:type=>"end"}},
                  :publication_date => {:path=>"date"}
                }

    # Correct usage of Start & End pages...
    # property :start_page, :path=>"extent", :attributes=>{:unit=>"pages"}, 
    #             :convenience_methods => {
    #               :number=>{:path=>"start"}
    #             }
    # property :end_page, :path=>"extent", :attributes=>{:unit=>"pages"}, 
    #             :convenience_methods => {
    #               :number=>{:path=>"end"}
    #             }
    # property :volume, :path=>"detail", :attributes=>{:type=>"volume"}, :subelements=>"number"
    # property :level, :path=>"detail", :attributes=>{:type=>"number"}, :subelements=>"number"
               
    generate_accessors_from_properties  
    
    accessor :title,  :relative_xpath=>'oxns:mods/oxns:titleInfo/oxns:title'
    
    # Generates an empty Mods Article (used when you call ModsArticle.new without passing in existing xml)
    def self.xml_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.mods(:version=>"3.3", "xmlns:xlink"=>"http://www.w3.org/1999/xlink",
           "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
           "xmlns"=>"http://www.loc.gov/mods/v3",
           "xsi:schemaLocation"=>"http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd") {
             xml.titleInfo {
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
                 # A hack implementation to reduce nesting
                 xml.detail(:type=>"volume")
                 xml.detail(:type=>"number")
                 xml.pages(:type=>"start")
                 xml.pages(:type=>"end")
                 
                 # The correct implementation (nesting too deep for current version of OM)
                 # xml.detail(:type=>"volume") {
                 #   xml.number
                 # }
                 # xml.detail(:type=>"number") {
                 #   xml.number
                 # }
                 # xml.extent(:unit=>"page") {
                 #   xml.start
                 #   xml.end
                 # }
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
    
    # Generates a new Person node
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
    
    # Generates a new Organization node
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
    
    # Generates a new Conference node
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
    
    def insert_contributor(type, opts={})
      case type.to_sym 
      when :person
        node = Hydra::ModsArticle.person_template
        nodeset = self.retrieve(:person)
      when :organization
        node = Hydra::ModsArticle.organization_template
        nodeset = self.retrieve(:organization)
      when :conference
        node = Hydra::ModsArticle.conference_template
        nodeset = self.retrieve(:conference)
      else
        ActiveFedora.logger.warn("#{type} is not a valid argument for Hydra::ModsArticle.insert_contributor")
        node = nil
        index = nil
      end
      
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
    
    def self.common_relator_terms
       {"aut" => "Author",
        "clb" => "Collaborator",
        "com" => "Compiler",
        "ctb" => "Contributor",
        "cre" => "Creator",
        "edt" => "Editor",
        "ill" => "Illustrator",
        "oth" => "Other",
        "trl" => "Translator",
        }
    end
      
    def self.relator_terms
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
        "wde" => "Wood -engraver",
        "wit" => "Witness"}
      end
    
end
end