# gamma-fixtures
#
# This was extracted from the original Hydra version in 
#                      ~/rvm/gems/<rails version>@gamma/bundler/gems/lib/railties
# It has been changed to read all files out of a directory and pass those as fixtures.
# Any _ in the file name will be modified to a : for the id, since colons are not valid in a file name. 
# The files should be named id_[id name] which should relates to the id within the foxml id:[id name] where 
# [id name] is some alpha numeric id ('test1')
#
# There are 2 sets of data needed to attach to a Gamma fixture, 1 the data file, and 2 the metadata.
# It is important that the meta-data contains the appropriate id, or solor will not index it!
#
# Example meta-data:
#
#    <info:fedora/id:[id name]> <http://purl.org/dc/terms/publisher> "CAC" .
#    <info:fedora/id:[id name]> <http://purl.org/dc/terms/description> "Test Fixture 2" .
#    <info:fedora/id:[id name]> <http://purl.org/dc/terms/created> "4/6/2012" .
#    <info:fedora/id:[id name]> <http://purl.org/dc/terms/contributor> "CAC" .
#    <info:fedora/id:[id name]> <http://purl.org/dc/terms/title> "Test Fixture 2 (Title)" .
#    <info:fedora/id:[id name]> <http://purl.org/dc/terms/relation> "test" .
#    <info:fedora/id:[id name]> <http://purl.org/dc/terms/subject> "Testing Fixture 2" .
#    <info:fedora/id:[id name]> <http://purl.org/dc/terms/language> "En" .
#    <info:fedora/id:[id name]> <http://xmlns.com/foaf/0.1/based_near> "State College" .
#    <info:fedora/id:[id name]> <http://purl.org/dc/terms/rights> "cac" .
#    <info:fedora/id:[id name]> <http://purl.org/dc/terms/creator> "CAC" .
#    <info:fedora/id:[id name]> <http://purl.org/dc/terms/identifier> "fixture" .
#
# Example foxml:  (note the ID needs to be unique) (the binary data in the xml below was generated using base64 on the text)
#    <?xml version="1.0" encoding="UTF-8"?>
#    <foxml:digitalObject PID="id:[id name]" VERSION="1.1" xmlns:foxml="info:fedora/fedora-system:def/foxml#"
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
#              <dc:identifier>id:[id name]</dc:identifier>
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
#              <rdf:Description rdf:about="info:fedora/id:[id name]">
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
# Usage: rake gamma:fixtures:delete [DIR=<fixture dir>]
#              <fixture dir> is an optional directory under test_support/fixtures to find the fixtures to load
#                            it defaults to gamma
#                                  (seed/develop was a convention I grabbed from some other fixture 
#                                    code and seemed reasonable so that you could have seed/prod ect.)
namespace :gamma do
  
  desc "Init Hydra configuration" 
  task :init => [:environment] do
    # We need to just start rails so that all the models are loaded
  end


  namespace :fixtures do
    @localDir = 'test_support/fixtures'
    if ENV["FIXTURE_DIR"]
          @dir= ENV["FIXTURE_DIR"]
    else
          @dir= 'gamma'
    end

    @fixtures = [
        "not-changed"
    ]

    desc "Generate default Gamma Hydra fixtures"
    task :create do

      if ENV["FIXTURE_ID"]
         @id= ENV["FIXTURE_ID"]
      else
         @id= 'gamma1'
      end

      if ENV["FIXTURE_TITLE"]
         @title= ENV["FIXTURE_TITLE"]
      else
         @title= 'gamma test'
      end

      if ENV["FIXTURE_USER"]
         @user= ENV["FIXTURE_USER"]
      else
         @user= 'gamma'
      end

      @root ='<%=Rails.root%>'

      @inputFoxmlFile = File.join(Rails.root, @localDir, @dir, 'id_generic_stub.foxml.erb')
      @inputDescFile = File.join(Rails.root, @localDir, @dir, 'id_generic_stub.descMeta.txt')
      @inputTxtFile = File.join(Rails.root, @localDir, @dir, 'id_generic_stub.txt')

      @outputFoxmlFile = File.join(Rails.root, @localDir, @dir, 'id_'+@id+'.foxml.erb')
      @outputDescFile = File.join(Rails.root, @localDir, @dir, 'id_'+@id+'.descMeta.txt')
      @outputTxtFile = File.join(Rails.root, @localDir, @dir, 'id_'+@id+'.txt')

      run_erb_stub @inputFoxmlFile, @outputFoxmlFile
      run_erb_stub @inputDescFile, @outputDescFile
      run_erb_stub @inputTxtFile, @outputTxtFile

    end


    desc "Generate default Gamma Hydra fixtures"
    task :generate do
      ENV["dir"] = File.join(Rails.root, @localDir, @dir) 
      find_fixtures_erb @dir
      @fixtures.each do |fixture|
        if fixture.index('generic_stub') == nil 
            print "input file: ",fixture, "\n"
            @outFile = fixture.sub('foxml.erb','foxml.xml')
            print "output file: ", @outFile, "\n"
            File.open(@outFile, "w+") do |f|
              f.write(ERB.new(get_erb_template fixture).result())
            end
        end
      end
    end

   
    desc "Load default Gamma Hydra fixtures"
    task :load do
      ENV["dir"] = File.join(Rails.root, @localDir, @dir) 
      find_fixtures @dir
      @noFixtures = true
      @fixtures.each do |fixture|
        print fixture, "\n"
        ENV["pid"] = fixture
        Rake::Task["repo:load"].reenable
        Rake::Task["repo:load"].invoke
        @noFixtures = false;
      end
      if @noFixtures
          print "No fixtures found you may need to generate from erb use:\n     rake gamma:fixtures:generate\n"
      end
    end

    desc "Remove default Gamma Hydra fixtures"
    task :delete do
      ENV["dir"] = File.join(Rails.root, @localDir, @dir) 
      find_fixtures @dir
      @fixtures.each do |fixture|
        print fixture, "\n"
        ENV["pid"] = fixture
        Rake::Task["repo:delete"].reenable
        Rake::Task["repo:delete"].invoke
      end
    end

    desc "Refresh default Gamma Hydra fixtures"
    task :refresh => [:delete, :load]

    private


    def run_erb_stub( inputFile, outputFile)
      print "input Fixture file: ", inputFile, "\n"
      print "output Fixture file: ", outputFile, "\n"
      File.open(outputFile, "w+") do |f|
         f.write(ERB.new(get_erb_template inputFile).result())
      end
    end

    def find_fixtures(dir)
       @fixtures = []
       Dir.glob(File.join(Rails.root, @localDir, dir, '*.foxml.xml')).each do |fixture_file|
          @fixtures <<  File.basename(fixture_file, '.foxml.xml').gsub('_',':')
       end
    end
    
    def find_fixtures_erb(dir)
       @fixtures = []
       Dir.glob(File.join(Rails.root, @localDir, dir, '*.foxml.erb')).each do |fixture_file|
          @fixtures <<  fixture_file
       end
    end



    def get_erb_template(file)
      File.read(file)
    end

  end
end
  
