module Sufia
  module Permissions
    extend ActiveSupport::Concern
    include Sufia::Permissions::Writable
    include Sufia::Permissions::Readable
  end
end
