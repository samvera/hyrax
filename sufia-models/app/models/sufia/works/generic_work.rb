# a very simple type of work with DC metadata
module Sufia::Works
  class GenericWork < Work
    include Sufia::Works::CurationConcern::WithBasicMetadata
  end
end
