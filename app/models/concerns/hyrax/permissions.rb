module Hyrax
  module Permissions
    extend ActiveSupport::Concern
    include Hyrax::Permissions::Writable
    include Hyrax::Permissions::Readable
    include Hyrax::Permissions::PermissionTemplates
  end
end
