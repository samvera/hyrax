# frozen_string_literal: true
module Hyrax
  class EmbargoesController < ApplicationController
    include Hyrax::EmbargoesControllerBehavior
    include Hyrax::ThemedLayoutController

    with_themed_layout 'dashboard'
  end
end
