# a very simple type of work with DC metadata
module Sufia::Works
  module GenericWork
    extend ActiveSupport::Concern

    include Sufia::Works::Work
    include Sufia::Works::CurationConcern::WithBasicMetadata
    include Sufia::GenericFile::Permissions
    include Sufia::GenericFile::Metadata
  end
end
