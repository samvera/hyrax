class CollectionsController < ApplicationController
  include Sufia::CollectionsControllerBehavior
  include Sufia::BreadcrumbsForCollections
end
