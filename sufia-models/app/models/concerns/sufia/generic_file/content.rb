module Sufia
  module GenericFile
    module Content
      extend ActiveSupport::Concern

      included do
        contains "content"
        contains "thumbnail"
      end

    end
  end
end
