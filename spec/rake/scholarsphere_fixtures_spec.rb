# Used to test the scholarsphere-fixtures rake task
#
require "spec_helper"
require "rake"


describe "scholarsphere:fixtures:*" do


    def loaded_files_excluding_current_rake_file
      $".reject {|file| file.include? "lib/tasks/scholarsphere-fixtures" }
    end


    # saves original $stdout in variable
    # set $stdout as local instance of StringIO
    # yields to code execution
    # returns the local instance of StringIO
    # resets $stout to original value
    def capture_stdout
      out = StringIO.new
      $stdout = out
      yield
      return out.string
    ensure
      $stdout = STDOUT
    end
    
    # this routine is in essence doing the following require without hard coding the path and fedora version
    #Rake.application.rake_require( "lib/tasks/active_fedora", "/home/carolyn/.rvm/gems/ree-1.8.7-2011.03@scholarsphere/bundler/gems/active_fedora-b64dcc516a05",
    def require_fedora
       @tmpName = "___fedoraVerOut.txt"
       system("bundle show active-fedora > #{@tmpName}")
       @file = File.open(@tmpName, "r") 
       @fedoraGem = @file.read.lstrip.rstrip
       File.delete(@tmpName)
       Rake.application.rake_require( "lib/tasks/active_fedora", [@fedoraGem], loaded_files_excluding_current_rake_file)      
    end
    
    #load the required rake tasks before each test
   before (:each) do
     @rake = Rake::Application.new 
     Rake.application = @rake
     Rake.application.rake_require( "lib/tasks/scholarsphere-fixtures", ["."], loaded_files_excluding_current_rake_file)
     require_fedora
     Rake::Task.define_task(:environment)
   end
   
    # unload the rake tests after each test
    after (:each) do
      @rake = nil
      Rake.application = nil
    end

  describe 'scholarsphere:fixtures:create' do        
    
    it 'should create a fixture' do
      ENV["FIXTURE_ID"] = "rspecTestFixture" 
      ENV["FIXTURE_TITLE"] = "rspec Test Fixture" 
      ENV["FIXTURE_USER"] = "rspec"
     
      o = capture_stdout do
        @rake['scholarsphere:fixtures:create'].invoke      
      end
      Dir.glob(Rails.root.join(File.expand_path("test_support/fixtures/scholarsphere"), "scholarsphere_rspecTestFixture.txt")).length.should == 1
      Dir.glob(Rails.root.join(File.expand_path("test_support/fixtures/scholarsphere"), "scholarsphere_rspecTestFixture.foxml.erb")).length.should == 1
      Dir.glob(Rails.root.join(File.expand_path("test_support/fixtures/scholarsphere"), "scholarsphere_rspecTestFixture.descMeta.txt")).length.should == 1
      
    end    
  end


  describe 'scholarsphere:fixtures:generate' do        
    
    it 'should generate an xml file' do
      
      o = capture_stdout do
        @rake['scholarsphere:fixtures:generate'].invoke      
      end
      Dir.glob(Rails.root.join(File.expand_path("test_support/fixtures/scholarsphere"), "scholarsphere_rspecTestFixture.foxml.xml")).length.should == 1
      
    end    
  end


  describe 'scholarsphere:fixtures:load' do        
    
    it 'should load fixtures' do
      
      o = capture_stdout do
        @rake['scholarsphere:fixtures:delete'].invoke      
        @rake['scholarsphere:fixtures:load'].invoke      
      end
      
     o.should include "Loaded 'scholarsphere:rspecTestFixture'"
      
    end    
  end


  describe 'scholarsphere:fixtures:delete' do        
    
    it 'should delete fixtures' do
      
      o = capture_stdout do
        @rake['scholarsphere:fixtures:delete'].invoke      
      end
      
     o.should include "Deleted 'scholarsphere:rspecTestFixture'"
      
    end    
  end

  describe 'scholarsphere:fixtures:refresh' do        
    
    it 'should refresh fixtures' do
      
      o = capture_stdout do
        @rake['scholarsphere:fixtures:load'].invoke      
        @rake['scholarsphere:fixtures:refresh'].invoke      
      end
      
     o.should include "Deleted 'scholarsphere:rspecTestFixture'"
     o.should include "Loaded 'scholarsphere:rspecTestFixture'"
      
    end    
  end

  
 
  
end
