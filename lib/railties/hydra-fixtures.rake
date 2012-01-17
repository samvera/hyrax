require "active-fedora"
require "solrizer-fedora"
require "active_support" # This is just to load ActiveSupport::CoreExtensions::String::Inflections
namespace :hydra do
  
  desc "[DEPRECATED] Delete and re-import the fixture identified by pid" 
  task :refresh_fixture do
    STDERR.puts "DEPRECATED: hydra:refresh_fixture is deprecated.  Use/override repo:refresh instead."
    Rake::Task["repo:refresh"].invoke
  end
  
  desc "[DEPRECATED] Delete the object identified by pid. Example: rake hydra:delete pid=demo:12"
  task :delete do
    STDERR.puts "DEPRECATED: hydra:delete is deprecated.  Use/override repo:delete instead."
    Rake::Task["repo:delete"].invoke
  end
  
  desc "[DEPRECATED] Delete a range of objects in a given namespace.  ie 'rake hydra:purge_range[demo, 22, 50]' will delete demo:22 through demo:50"
  task :purge_range do |t, args|
    STDERR.puts "DEPRECATED: hydra:purge_range is deprecated.  Use/override repo:delete_range instead."
    Rake::Task["repo:delete_range"].invoke
  end

  desc "[DEPRECATED] Export the object identified by pid into test_support/fixtures. Example:rake hydra:harvest_fixture pid=druid:sb733gr4073 source=http://fedoraAdmin:fedoraAdmin@127.0.0.1:8080/fedora"
  task :harvest_fixture do
    STDERR.puts "DEPRECATED: hydra:harvest_fixture is deprecated.  Use/override repo:export instead."
    if ENV["path"].nil?
      ENV["path"] = File.join("test_support","fixtures")
    end
    Rake::Task["repo:export"].invoke
  end
  
  desc "[DEPRECATED] Import the fixture located at the provided path. Example: rake hydra:import_fixture fixture=test_support/fixtures/demo_12.foxml.xml"
  task :import_fixture do
    STDERR.puts "DEPRECATED: hydra:import_fixture is deprecated.  Use/override repo:load instead."
    if !ENV["pid"].nil?
      pid = ENV["pid"]
      ENV["pid"] = nil
      ENV["path"] = File.join("test_support","fixtures","#{pid.gsub(":","_")}.foxml.xml")
     end
     Rake::Task["repo:load"].invoke
  end

  namespace :default_fixtures do
    desc "[DEPRECATED] Load default Hydra fixtures"
    task :load do
      STDERR.puts "DEPRECATED: hydra:default_fixtures:load is deprecated.  Use/override hydra:fixtures:load instead."
      Rake::Task["hydra:fixtures:load"].invoke	
    end

    desc "[DEPRECATED] Remove default Hydra fixtures"
    task :delete do
      STDERR.puts "DEPRECATED: hydra:default_fixtures:delete is deprecated.  Use/override hydra:fixtures:delete instead."
      Rake::Task["hydra:fixtures:delete"].invoke	
    end

    desc "[DEPRECATED] Refresh default Hydra fixtures"
    task :refresh do
      STDERR.puts "DEPRECATED: hydra:default_fixtures:refresh is deprecated.  Use/override hydra:fixtures:refresh instead."
      Rake::Task["hydra:fixtures:refresh"].invoke	
    end
  end
  
  desc "Init Hydra configuration" 
  task :init => [:environment] do
    # We need to just start rails so that all the models are loaded
  end

  desc "Load hydra-head models"
  task :load_models do
    require "hydra"
    Dir.glob(File.join(File.expand_path(File.dirname(__FILE__)), "..",'app','models', '*.rb')).each do |model|
      load model
    end
  end

  namespace :fixtures do
    FIXTURES = [
        "hydrangea:fixture_mods_article1",
        "hydrangea:fixture_mods_article3",
        "hydrangea:fixture_file_asset1",
        "hydrangea:fixture_mods_article2",
        "hydrangea:fixture_uploaded_svg1",
        "hydrangea:fixture_archivist_only_mods_article",
        "hydrangea:fixture_mods_dataset1",
        "libra-oa:1", "libra-oa:2", "libra-oa:7",
        "hydrus:admin_class1",
        "hydra:test_generic_content",
        "hydra:test_generic_image",
        "hydra:test_default_partials",
        "hydra:test_no_model"
    ]
    desc "Load default Hydra fixtures"
    task :load do
      FIXTURES.each do |fixture|
        ENV["path"] = File.join("test_support","fixtures","#{fixture.gsub(":","_")}.foxml.xml")
        Rake::Task["repo:load"].reenable
        Rake::Task["repo:load"].invoke
      end
    end

    desc "Remove default Hydra fixtures"
    task :delete do
      FIXTURES.each do |fixture|
        ENV["pid"] = fixture
        Rake::Task["repo:delete"].reenable
        Rake::Task["repo:delete"].invoke
      end
    end

    desc "Refresh default Hydra fixtures"
    task :refresh => [:delete, :load]

  end
  
end
