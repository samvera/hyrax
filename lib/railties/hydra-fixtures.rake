require "active-fedora"
require "solrizer-fedora"
require "active_support" # This is just to load ActiveSupport::CoreExtensions::String::Inflections
namespace :hydra do
  
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
      ENV["dir"] = File.join("test_support", "fixtures")
      FIXTURES.each do |fixture|
        ENV["pid"] = fixture
        Rake::Task["repo:load"].reenable
        Rake::Task["repo:load"].invoke
      end
    end

    desc "Remove default Hydra fixtures"
    task :delete do
      ENV["dir"] = File.join("test_support", "fixtures")
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
  
