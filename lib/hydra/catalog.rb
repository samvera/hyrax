require 'hydra/controller/catalog_controller_behavior'
require 'deprecation'
module Hydra::Catalog
  extend ActiveSupport::Concern
  extend Deprecation

  included do
    Deprecation.warn(Hydra::Catalog, "Hydra::Catalog is deprecated and is replaced by Hydra::Controller::CatalogControllerBehavior.")
    include Hydra::Controller::CatalogControllerBehavior
  end
end
