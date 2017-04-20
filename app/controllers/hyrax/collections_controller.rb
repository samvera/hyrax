# frozen_string_literal: true

module Hyrax
  class CollectionsController < ApplicationController
    include CollectionsControllerBehavior
    include BreadcrumbsForCollections
  end
end
