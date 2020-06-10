# frozen_string_literal: true
module Hyrax
  class EmbargoesController < ApplicationController
    include Hyrax::EmbargoesControllerBehavior

    with_themed_layout 'dashboard'
  end
end
