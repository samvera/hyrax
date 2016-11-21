module Sufia
  class FileSetsController < ApplicationController
    include CurationConcerns::FileSetsControllerBehavior
    include Sufia::FileSetsControllerBehavior
  end
end
