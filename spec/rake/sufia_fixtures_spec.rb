require 'spec_helper'

# Used to test the sufia-fixtures rake task
require "rake"

describe "sufia:fixtures" do

  def loaded_files_excluding_current_rake_file
    $".reject { |file| file.include? "tasks/sufia-fixtures" }
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
    File.delete(File.join(File.expand_path("#{fixture_path}/sufia"), "sufia_rspecTestFixture.txt"))
    File.delete(File.join(File.expand_path("#{fixture_path}/sufia"), "sufia_rspecTestFixture.descMeta.txt"))
    File.delete(File.join(File.expand_path("#{fixture_path}/sufia"), "sufia_rspecTestFixture.foxml.erb"))
    begin
      File.delete(File.join(File.expand_path("#{fixture_path}/sufia"), "sufia_rspecTestFixture.foxml.xml"))
    rescue
      # do nothing; this just means the generate task was not called
    end
  end

  # set up the rake environment
  before(:each) do
    @rake = Rake::Application.new 
    Rake.application = @rake
    Rake.application.rake_require("sufia-fixtures", ["#{Sufia::Engine.root}/tasks/"], loaded_files_excluding_current_rake_file)
    Rake.application.rake_require("fixtures", ["#{Sufia::Engine.root}/lib/tasks/"], loaded_files_excluding_current_rake_file)
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
        @rake['sufia:fixtures:create'].invoke
        @rake['sufia:fixtures:generate'].invoke
        @rake['sufia:fixtures:load'].invoke       
        @rake['sufia:fixtures:delete'].invoke
      end
      Dir.glob(File.join(fixture_path, File.expand_path("/sufia"), "sufia_rspecTestFixture.txt")).length.should == 1
      Dir.glob(File.join(fixture_path, File.expand_path("/sufia"), "sufia_rspecTestFixture.foxml.erb")).length.should == 1
      Dir.glob(File.join(fixture_path, File.expand_path("/sufia"), "sufia_rspecTestFixture.descMeta.txt")).length.should == 1
      Dir.glob(File.join(fixture_path, File.expand_path("/sufia"), "sufia_rspecTestFixture.foxml.xml")).length.should == 1
      o.should include "Loaded 'sufia:rspecTestFixture'"
      o.should include "Deleted 'sufia:rspecTestFixture'"
    end    
  end
end
