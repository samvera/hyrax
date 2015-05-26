module CurationConcern
  class GenericWorksController < ApplicationController
    include CurationConcerns::CurationConcernController
    set_curation_concern_type GenericWork
  end
end