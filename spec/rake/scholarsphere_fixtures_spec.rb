# Used to test the scholarsphere-fixtures rake task
#
require "spec_helper"
require "rake"

describe "scholarsphere:fixtures" do

  def loaded_files_excluding_current_rake_file
    $".reject { |file| file.include? "lib/tasks/scholarsphere-fixtures" }
  end

  # saves original $stdout in variable
  # set $stdout as local instance of StringIO
  # yields to code execution
  # returns the local instance of StringIO
  # resets $stdout to original value
  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    return out.string
  ensure
    $stdout = STDOUT
  end
  
  def activefedora_path
    Gem.loaded_specs['active-fedora'].full_gem_path
  end
  
  def delete_fixture_files
    File.delete(Rails.root.join(File.expand_path("spec/fixtures/scholarsphere"), "scholarsphere_rspecTestFixture.txt"))
    File.delete(Rails.root.join(File.expand_path("spec/fixtures/scholarsphere"), "scholarsphere_rspecTestFixture.descMeta.txt"))
    File.delete(Rails.root.join(File.expand_path("spec/fixtures/scholarsphere"), "scholarsphere_rspecTestFixture.foxml.erb"))
    begin
      File.delete(Rails.root.join(File.expand_path("spec/fixtures/scholarsphere"), "scholarsphere_rspecTestFixture.foxml.xml"))
    rescue
      # do nothing; this just means the generate task was not called
    end
  end

  # set up the rake environment
  before(:each) do
    @rake = Rake::Application.new 
    Rake.application = @rake
    Rake.application.rake_require("lib/tasks/scholarsphere-fixtures", ["."], loaded_files_excluding_current_rake_file)
    Rake.application.rake_require("lib/tasks/active_fedora", [activefedora_path], loaded_files_excluding_current_rake_file)      
    Rake::Task.define_task(:environment)
  end

  after(:each) do
    delete_fixture_files
  end
    
  describe 'create, generate, load and delete' do
    it 'should load and then delete fixtures' do
      ENV["FIXTURE_ID"] = "rspecTestFixture" 
      ENV["FIXTURE_TITLE"] = "rspec Test Fixture" 
      ENV["FIXTURE_USER"] = "rspec"
      o = capture_stdout do
        @rake['scholarsphere:fixtures:create'].invoke
        @rake['scholarsphere:fixtures:generate'].invoke
        @rake['scholarsphere:fixtures:load'].invoke       
        @rake['scholarsphere:fixtures:delete'].invoke
      end
      Dir.glob(Rails.root.join(File.expand_path("spec/fixtures/scholarsphere"), "scholarsphere_rspecTestFixture.txt")).length.should == 1
      Dir.glob(Rails.root.join(File.expand_path("spec/fixtures/scholarsphere"), "scholarsphere_rspecTestFixture.foxml.erb")).length.should == 1
      Dir.glob(Rails.root.join(File.expand_path("spec/fixtures/scholarsphere"), "scholarsphere_rspecTestFixture.descMeta.txt")).length.should == 1
      Dir.glob(Rails.root.join(File.expand_path("spec/fixtures/scholarsphere"), "scholarsphere_rspecTestFixture.foxml.xml")).length.should == 1
      o.should include "Loaded 'scholarsphere:rspecTestFixture'"
      o.should include "Deleted 'scholarsphere:rspecTestFixture'"
    end    
  end
end
