class CollectionsController < ApplicationController
  include Hyrax::CollectionsControllerBehavior
  include Hyrax::BreadcrumbsForCollections
end
