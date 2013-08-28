# sufia-fixtures
#
# This was extracted from the original Hydra version in 
#                      ~/rvm/gems/<rails version>@sufia/bundler/gems/lib/railties
# It has been changed to read all files out of a directory and pass those as fixtures.
# Any _ in the file name will be modified to a : for the id, since colons are not valid in a file name. 
# The files should be named id_[fixture id] which should relates to the id within the foxml sufia:[fixture id] where 
# [fixture id] is some alpha numeric id ('test1')
#
# There are 2 sets of data needed to attach to a sufia fixture, 1 the data file, and 2 the metadata.
# It is important that the meta-data contains the appropriate id, or solor will not index it!
#
# Usage: rake sufia:fixtures:create [DIR=<fixture dir>] [FIXTURE_ID=<fixture id>] [FIXTURE_TITLE=<fixture title>] [FIXTURE_USER=<fixture user>]
#              <fixture dir> is an optional directory under spec/fixtures to find the fixtures to load
#                      DEFAULT: sufia
#              <fixture id> is the id given to this fixture with fedora and solr.   
#                            This must be unique and any old files will be overwritten. 
#                      DEFAULT: sufia1
#              <fixture title> is the title given to the fixture in fedora and solor, 
#                            along with being put in the description and subject by default.
#                      DEFAULT: sufia test
#              <fixture user> is the user given to the fixture in fedora and solor, 
#                            along with being put in the contributor and rights.
#                      DEFAULT: archivist1
#           
#          
#               Creates new fixture files including the erb, descMeta, and text for loading into sufia.  
#               The Files are named based on the sufia: id_<fixture id>.foxml.erb, id_<fixture id>.descMeta.txt, and id_<fixture id>.txt
#               The foxml.erb file references the descMeta.txt and .txt file.  You can edit the erb to point to other data and/or edit the 
#               .descMeta.txt  and/or .txt file to contain the data you wish.  
#
#            *** Please note that the id must be changed in the file name, foxml.erb, and descMeta.txt if you change it after creation. ***
#
#        rake sufia:fixtures:generate [DIR=<fixture dir>]
#              <fixture dir> is an optional directory under spec/fixtures to find the fixtures to load
#                      DEFAULT: sufia
#
#               Creates foxml.xml files from the foxml.erb files doing any erb substitutions within the erb file.
#               This task is mostly used to put the appropriate Rails.root into the foxml.xml file so that 
#               the data and meta-data files can be located on load. 
#
#        rake sufia:fixtures:delete [DIR=<fixture dir>]
#              <fixture dir> is an optional directory under spec/fixtures to find the fixtures to load
#                      DEFAULT: sufia
#
#               Remove any fixtures defined by .xml.foxml files in Rais.root/spec/fixtures/<fixture dir> from fedora and solr. 
#
#        rake sufia:fixtures:load [DIR=<fixture dir>]
#              <fixture dir> is an optional directory under spec/fixtures to find the fixtures to load
#                      DEFAULT: sufia
#
#               load any fixtures defined by .xml.foxml files in Rais.root/spec/fixtures/<fixture dir> into fedora and solr. 
#
#        rake sufia:fixtures:refresh [DIR=<fixture dir>]
#              <fixture dir> is an optional directory under spec/fixtures to find the fixtures to load
#                      DEFAULT: sufia
#
#               delete then load any fixtures defined by .xml.foxml files in Rais.root/spec/fixtures/<fixture dir> into fedora and solr. 
#
# Example meta-data:
#
#    <info:fedora/sufia:[fixture id]> <http://purl.org/dc/terms/publisher> "archivist1" .
#    <info:fedora/sufia:[fixture id]> <http://purl.org/dc/terms/description> "MP3 Description" .
#    <info:fedora/sufia:[fixture id]> <http://purl.org/dc/terms/created> "04/12/2012" .
#    <info:fedora/sufia:[fixture id]> <http://purl.org/dc/terms/contributor> "archivist1" .
#    <info:fedora/sufia:[fixture id]> <http://purl.org/dc/terms/title> "MP3" .
#    <info:fedora/sufia:[fixture id]> <http://purl.org/dc/terms/relation> "test" .
#    <info:fedora/sufia:[fixture id]> <http://purl.org/dc/terms/subject> "MP3 Test" .
#    <info:fedora/sufia:[fixture id]> <http://purl.org/dc/terms/language> "En" .
#    <info:fedora/sufia:[fixture id]> <http://xmlns.com/foaf/0.1/based_near> "State College" .
#    <info:fedora/sufia:[fixture id]> <http://purl.org/dc/terms/rights> "archivist1" .
#    <info:fedora/sufia:[fixture id]> <http://purl.org/dc/terms/creator> "archivist1" .
#    <info:fedora/sufia:[fixture id]> <http://purl.org/dc/terms/identifier> "Test" .
#
# Example foxml:  (note the ID needs to be unique) (the binary data in the xml below was generated using base64 on the text)
#    <?xml version="1.0" encoding="UTF-8"?>
#    <foxml:digitalObject PID="sufia:[fixture id]" VERSION="1.1" xmlns:foxml="info:fedora/fedora-system:def/foxml#"
#      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="info:fedora/fedora-system:def/foxml# http://www.fedora.info/definitions/1/0/foxml1-1.xsd">
#      <foxml:objectProperties>
#        <foxml:property NAME="info:fedora/fedora-system:def/model#state" VALUE="Active"/>
#        <foxml:property NAME="info:fedora/fedora-system:def/model#label" VALUE="testFixture2.txt"/>
#        <foxml:property NAME="info:fedora/fedora-system:def/model#ownerId" VALUE="fedoraAdmin"/>
#      </foxml:objectProperties>
#      <foxml:datastream CONTROL_GROUP="X" ID="DC" STATE="A" VERSIONABLE="true">
#        <foxml:datastreamVersion FORMAT_URI="http://www.openarchives.org/OAI/2.0/oai_dc/"
#          ID="DC1.0" LABEL="Dublin Core Record for this object" MIMETYPE="text/xml" SIZE="377">
#          <foxml:xmlContent>
#            <oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/"
#              xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
#              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
#              <dc:title>testFixture2.txt</dc:title>
#              <dc:identifier>sufia:[fixture id]</dc:identifier>
#            </oai_dc:dc>
#          </foxml:xmlContent>
#        </foxml:datastreamVersion>
#      </foxml:datastream>
#      <foxml:datastream CONTROL_GROUP="M" ID="descMetadata" STATE="A" VERSIONABLE="true">
#        <foxml:datastreamVersion ID="descMetadata.0" LABEL="" MIMETYPE="text/plain">
#          <foxml:binaryContent>  PGluZm86ZmVkb3JhL2lkOnRlc3QyPiA8aHR0cDovL3B1cmwub3JnL2RjL3Rlcm1zL3B1Ymxpc2hl
#    cj4gIkNBQyIgLgo8aW5mbzpmZWRvcmEvaWQ6dGVzdDI+IDxodHRwOi8vcHVybC5vcmcvZGMvdGVy
#    bXMvZGVzY3JpcHRpb24+ICJUZXN0IEZpeHR1cmUgMiIgLgo8aW5mbzpmZWRvcmEvaWQ6dGVzdDI+
#    IDxodHRwOi8vcHVybC5vcmcvZGMvdGVybXMvY3JlYXRlZD4gIjQvNi8yMDEyIiAuCjxpbmZvOmZl
#    ZG9yYS9pZDp0ZXN0Mj4gPGh0dHA6Ly9wdXJsLm9yZy9kYy90ZXJtcy9jb250cmlidXRvcj4gIkNB
#    QyIgLgo8aW5mbzpmZWRvcmEvaWQ6dGVzdDI+IDxodHRwOi8vcHVybC5vcmcvZGMvdGVybXMvdGl0
#    bGU+ICJUZXN0IEZpeHR1cmUgMiAoVGl0bGUpIiAuCjxpbmZvOmZlZG9yYS9pZDp0ZXN0Mj4gPGh0
#    dHA6Ly9wdXJsLm9yZy9kYy90ZXJtcy9yZWxhdGlvbj4gInRlc3QiIC4KPGluZm86ZmVkb3JhL2lk
#    OnRlc3QyPiA8aHR0cDovL3B1cmwub3JnL2RjL3Rlcm1zL3N1YmplY3Q+ICJUZXN0aW5nIEZpeHR1
#    cmUgMiIgLgo8aW5mbzpmZWRvcmEvaWQ6dGVzdDI+IDxodHRwOi8vcHVybC5vcmcvZGMvdGVybXMv
#    bGFuZ3VhZ2U+ICJFbiIgLgo8aW5mbzpmZWRvcmEvaWQ6dGVzdDI+IDxodHRwOi8veG1sbnMuY29t
#    L2ZvYWYvMC4xL2Jhc2VkX25lYXI+ICJTdGF0ZSBDb2xsZWdlIiAuCjxpbmZvOmZlZG9yYS9pZDp0
#    ZXN0Mj4gPGh0dHA6Ly9wdXJsLm9yZy9kYy90ZXJtcy9yaWdodHM+ICJjYWMiIC4KPGluZm86ZmVk
#    b3JhL2lkOnRlc3QyPiA8aHR0cDovL3B1cmwub3JnL2RjL3Rlcm1zL2NyZWF0b3I+ICJDQUMiIC4K
#    PGluZm86ZmVkb3JhL2lkOnRlc3QyPiA8aHR0cDovL3B1cmwub3JnL2RjL3Rlcm1zL2lkZW50aWZp
#    ZXI+ICJmaXh0dXJlIiAuCg==
#          </foxml:binaryContent>      
#        </foxml:datastreamVersion>
#      </foxml:datastream>
#      <foxml:datastream CONTROL_GROUP="X" ID="RELS-EXT" STATE="A" VERSIONABLE="true">
#        <foxml:datastreamVersion ID="RELS-EXT.0"
#          LABEL="Fedora Object-to-Object Relationship Metadata" MIMETYPE="application/rdf+xml" SIZE="286">
#          <foxml:xmlContent>
#            <rdf:RDF xmlns:ns0="info:fedora/fedora-system:def/model#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
#              <rdf:Description rdf:about="info:fedora/sufia:[fixture id]">
#                <ns0:hasModel rdf:resource="info:fedora/afmodel:GenericFile"/>
#              </rdf:Description>
#            </rdf:RDF>
#          </foxml:xmlContent>
#        </foxml:datastreamVersion>
#      </foxml:datastream>
#      <foxml:datastream CONTROL_GROUP="M" ID="content" STATE="A" VERSIONABLE="true">
#        <foxml:datastreamVersion ID="content.0" LABEL="testFixture2.txt"
#          MIMETYPE="text/plain" >
#          <foxml:binaryContent> VGhpcyBpcyBhIHRlc3QgZml4dHVyZS4gCkJpbmFyeSBkYXRhIGZvciBmaXh0dXJlIDIuCg== </foxml:binaryContent>      
#        </foxml:datastreamVersion>
#      </foxml:datastream>
#      <foxml:datastream CONTROL_GROUP="X" ID="rightsMetadata" STATE="A" VERSIONABLE="true">
#        <foxml:datastreamVersion ID="rightsMetadata.0" LABEL="" MIMETYPE="text/xml" SIZE="582">
#          <foxml:xmlContent>
#            <rightsMetadata version="0.1" xmlns="http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1">
#              <copyright>
#                <human/>
#                <machine>
#                  <uvalicense>no</uvalicense>
#                </machine>
#              </copyright>
#              <access type="discover">
#                <human/>
#                <machine/>
#              </access>
#              <access type="read">
#                <human/>
#                <machine/>
#              </access>
#              <access type="edit">
#                <human/>
#                <machine>
#                  <person>cam156@psu.edu</person>
#                </machine>
#              </access>
#              <embargo>
#                <human/>
#                <machine/>
#              </embargo>
#            </rightsMetadata>
#          </foxml:xmlContent>
#        </foxml:datastreamVersion>
#      </foxml:datastream>
#    </foxml:digitalObject>
#
#
#

require 'active_fedora'

SUFIA_TEST_NS = 'sufia' #this must be the same as id_namespace in the test applications config
namespace :sufia do
  namespace :fixtures do
    @localDir = File.expand_path("../../spec/fixtures", __FILE__)
    @dir = ENV["FIXTURE_DIR"] || 'sufia'

    desc "Create sufia Hydra fixtures for generation and loading"
    task :create  do
      @id = ENV["FIXTURE_ID"] ||'sufia1'
      @title = ENV["FIXTURE_TITLE"] || 'sufia test'
      @user = ENV["FIXTURE_USER"] || 'archivist1'

      @root ='<%=@localDir%>'

      @inputFoxmlFile = File.join(@localDir, 'sufia_generic_stub.foxml.erb')
      @inputDescFile = File.join(@localDir,  'sufia_generic_stub.descMeta.txt')
      @inputTxtFile = File.join(@localDir,  'sufia_generic_stub.txt')

      @outputFoxmlFile = File.join(@localDir, @dir, "#{SUFIA_TEST_NS}_#{@id}.foxml.erb")
      @outputDescFile = File.join(@localDir, @dir, "#{SUFIA_TEST_NS}_#{@id}.descMeta.txt")
      @outputTxtFile = File.join(@localDir, @dir, "#{SUFIA_TEST_NS}_#{@id}.txt")
      
      run_erb_stub @inputFoxmlFile, @outputFoxmlFile
      run_erb_stub @inputDescFile, @outputDescFile
      run_erb_stub @inputTxtFile, @outputTxtFile
    end

    desc "Generate default sufia Hydra fixtures"
    task :generate do
      ENV["dir"] = File.join(@localDir, @dir) 
      fixtures = find_fixtures_erb(@dir)
      fixtures.each do |fixture|
        unless fixture.include?('generic_stub')
          outFile = fixture.sub('foxml.erb','foxml.xml')
          File.open(outFile, "w+") do |f|
            f.write(ERB.new(get_erb_template fixture).result(binding))
          end
        end
      end
    end
   
    private

    def run_erb_stub(inputFile, outputFile)
      File.open(outputFile, "w+") do |f|
        f.write(ERB.new(get_erb_template inputFile).result())
      end
    end

    def find_fixtures_erb(dir)
      Dir.glob(File.join(@localDir, dir, '*.foxml.erb'))
    end

    def get_erb_template(file)
      File.read(file)
    end
  end
end
