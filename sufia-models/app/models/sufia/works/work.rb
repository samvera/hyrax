# The base class of all works
module Sufia::Works
  class Work < ActiveFedora::Base
    include Sufia::Works::CurationConcern::Work

  end
end
