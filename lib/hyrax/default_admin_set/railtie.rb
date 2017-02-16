require 'rails/railtie'

module Hyrax
  module DefaultAdminSet
    # Connect into the boot sequence of a Rails application
    class Railtie < Rails::Railtie
      config.to_prepare do
        begin
          AdminSet.find(Hyrax::DefaultAdminSetActor::DEFAULT_ID)
        rescue
          begin
            AdminSet.create!(id: Hyrax::DefaultAdminSetActor::DEFAULT_ID, title: ['Default Admin Set']).tap do |_as|
              PermissionTemplate.create!(admin_set_id: Hyrax::DefaultAdminSetActor::DEFAULT_ID)
            end
          rescue
            next
          end
        end
      end
    end
  end
end
