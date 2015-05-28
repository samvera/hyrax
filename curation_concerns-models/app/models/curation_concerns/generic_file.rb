module CurationConcerns
  class GenericFile < ActiveFedora::Base
    include CurationConcerns::GenericFileBehavior
  end
end
