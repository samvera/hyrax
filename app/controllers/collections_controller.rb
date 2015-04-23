# -*- coding: utf-8 -*-
class CollectionsController < ApplicationController
  include Worthwhile::CollectionsControllerBehavior
  with_themed_layout '1_column'
end
