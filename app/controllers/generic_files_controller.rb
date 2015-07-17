# -*- coding: utf-8 -*-
class GenericFilesController < ApplicationController
  include CurationConcerns::GenericFilesControllerBehavior
  include Sufia::Controller
  include Sufia::FilesControllerBehavior
end
