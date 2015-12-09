module CurationConcerns
  class FileSetsController < ApplicationController
    include CurationConcerns::FileSetsControllerBehavior
    include Sufia::Controller
    include Sufia::FileSetsControllerBehavior
  end
end
