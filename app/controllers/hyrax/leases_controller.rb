# frozen_string_literal: true
module Hyrax
  class LeasesController < ApplicationController
    include Hyrax::LeasesControllerBehavior

    with_themed_layout 'dashboard'
  end
end
