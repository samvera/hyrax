require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../support", __FILE__)

  # Inject call to Hydra::BatchEdit.add_routes in config/routes.rb
  def inject_routes
    insert_into_file "config/routes.rb", :after => '.draw do' do
      "\n  # Add HydraHead routes."
      "\n  HydraHead.add_routes(self)"
    end
  end

  def run_blacklight_generator
    say_status("warning", "GENERATING BL", :yellow)       

    generate 'blacklight', '--devise'
  end

  def run_hydra_head_generator
    say_status("warning", "GENERATING HH", :yellow)       

    generate 'hydra:head', '-f'
  end

  def copy_test_fixtures
    copy_file "app/models/generic_content.rb"
    copy_file "spec/factories/users.rb", :force=>true #overwrite the default factory set up by factory_girl_rails
    copy_file "spec/fixtures/hydrangea_fixture_mods_article1.foxml.xml" 
    copy_file "spec/fixtures/hydrangea_fixture_mods_article2.foxml.xml" 
    copy_file "spec/fixtures/hydrangea_fixture_mods_article3.foxml.xml" 
    copy_file "spec/fixtures/hydrangea_fixture_file_asset1.foxml.xml" 
    copy_file "spec/fixtures/hydrangea_fixture_uploaded_svg1.foxml.xml" 

    # For testing Hydra::SubmissionWorkflow
    #copy_file "spec/fixtures/hydra_test_generic_content.foxml.xml"
  end

end
