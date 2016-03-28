require 'rails/generators'

module CurationConcerns
  class Assets < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def remove_blacklight_scss
      remove_file 'app/assets/stylesheets/blacklight.css.scss'
    end

    def assets
      copy_file 'curation_concerns.scss', 'app/assets/stylesheets/curation_concerns.scss'
      copy_file 'curation_concerns.js', 'app/assets/javascripts/curation_concerns.js'
    end
  end
end
