module Sufia
  class Collection < ActiveFedora::Base
    include Sufia::CollectionBehavior
  end
end
