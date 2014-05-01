require 'rails/generators'

module Worthwhile
  class Install < Rails::Generators::Base

    source_root File.expand_path('../templates', __FILE__)

    def run_blacklight_generator
      say_status("warning", "GENERATING BL", :yellow)
      generate 'blacklight:install', '--devise'

      say_status("warning", "GENERATING HYDRA-HEAD", :yellow)
      generate "hydra:head -f"

      say_status("warning", "GENERATING SUFIA", :yellow)
      generate "sufia:models:install#{options[:force] ? ' -f' : ''}"
    end

    def remove_catalog_controller
      say_status("warning", "Removing Blacklight's generated CatalogController...", :yellow)
      remove_file('app/controllers/catalog_controller.rb')
    end

    def inject_routes
      route "mount Worthwhile::Engine, at: '/'"
    end

    def inject_ability
      inject_into_file 'app/models/ability.rb', :after => /Hydra::Ability\s*\n/ do
        "  include Worthwhile::Ability\n\n"
      end
    end

    def assets
      copy_file "worthwhile.css.scss", "app/assets/stylesheets/worthwhile.css.scss"
      copy_file "worthwhile.js", "app/assets/javascripts/worthwhile.js"
    end

    def add_helper
      copy_file "worthwhile_helper.rb", "app/helpers/worthwhile_helper.rb"
      #inject_into_class 'app/helpers/application_helper.rb', ApplicationHelper, "  include WorthwhileHelper"
    end
  end
end
