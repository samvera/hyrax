module CurationConcern
  class GenericWorksController < ApplicationController
    include Worthwhile::CurationConcernController
    set_curation_concern_type GenericWork
  end
end