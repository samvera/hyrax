# -*- encoding : utf-8 -*-
# Copy Blacklight assets to public folder in current app. 
# If you want to do this on application startup, you can
# add this next line to your one of your environment files --
# generally you'd only want to do this in 'development', and can
# add it to environments/development.rb:
#       require File.join(Hydra.root, "lib", "generators", "hydra", "assets_generator.rb")
#       Hydra::Assets.start(["--force", "--quiet"])


# Need the requires here so we can call the generator from environment.rb
# as suggested above. 
require 'rails/generators'
require 'rails/generators/base'
module Hydra
  class Assets < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
  
    def assets
      if use_asset_pipeline?
        insert_into_file "app/assets/stylesheets/application.css", :after => " *= require_self" do
%q{
 *
 * Required by Hydra
 *= require 'hydra/styles'         
}
        end

        insert_into_file "app/assets/javascripts/application.js", :after => "//= require jquery_ujs" do
%q{
// Required by Hydra
//= require 'jquery.hydraMetadata.js'         
//= require 'jquery.ui.datepicker.js'      
}          
        end
        directory("../../../../app/assets/images/blacklight", "public/images/blacklight")
      else
        # directories are relative to the source_root 
        directory("../../../../assets/images", "public/images")
        directory("../../../../assets/stylesheets", "public/stylesheets") 
        directory("../../../../assets/javascripts", "public/javascripts") 
      end
    end

    private
    def use_asset_pipeline?
      (Rails::VERSION::MAJOR >= 3 and Rails::VERSION::MINOR >= 1) and Rails.application.config.assets.enabled
    end
    
  end
end
