module Hyrax
  class EmbargoesController < ApplicationController
    include Hyrax::EmbargoesControllerBehavior

    with_themed_layout 'dashboard'
  end
end
