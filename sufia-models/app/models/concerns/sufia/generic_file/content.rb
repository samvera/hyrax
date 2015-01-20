module Sufia
  module GenericFile
    module Content
      extend ActiveSupport::Concern

      included do
        contains "content", class_name: 'FileContentDatastream'
        contains "thumbnail"
      end

    end
  end
end
