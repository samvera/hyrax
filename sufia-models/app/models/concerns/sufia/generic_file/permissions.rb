module Sufia
  module FileSet
    module Permissions
      extend ActiveSupport::Concern

      include Sufia::Permissions::Writable
      include Sufia::Permissions::Readable
    end
  end
end
