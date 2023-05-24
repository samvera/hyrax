# frozen_string_literal: true
module Hyrax
  class LeasesController < ApplicationController
    include Hyrax::LeasesControllerBehavior
    include Hyrax::ThemedLayoutController

    with_themed_layout 'dashboard'
  end
end
