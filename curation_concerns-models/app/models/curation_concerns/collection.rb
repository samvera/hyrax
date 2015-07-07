module CurationConcerns
  class Collection < ActiveFedora::Base
    include CurationConcerns::CollectionBehavior
  end
end
