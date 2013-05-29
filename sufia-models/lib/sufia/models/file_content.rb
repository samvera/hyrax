module Sufia
  module FileContent
    extend ActiveSupport::Autoload

    autoload :ExtractMetadata, 'sufia/models/file_content/extract_metadata'
    autoload :Versions, 'sufia/models/file_content/versions'

  end
end
