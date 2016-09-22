require 'rails/generators'

module CurationConcerns
  class AdminDashboardGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    desc 'This generator makes the following changes to your application:
   1. Creates an admin dashboard controller.
'

    def create_controller
      copy_file 'app/controllers/curation_concerns/admin_controller.rb', 'app/controllers/curation_concerns/admin_controller.rb'
    end
  end
end
