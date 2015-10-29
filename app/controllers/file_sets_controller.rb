# -*- coding: utf-8 -*-
class FileSetsController < ApplicationController
  include CurationConcerns::FileSetsControllerBehavior
  include Sufia::Controller
  include Sufia::FilesControllerBehavior
end
