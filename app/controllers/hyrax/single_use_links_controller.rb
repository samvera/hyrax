# frozen_string_literal: true

module Hyrax
  class SingleUseLinksController < ApplicationController
    include Hyrax::SingleUseLinksControllerBehavior
  end
end
