module Hydra::Catalog
  extend ActiveSupport::Concern
  include Blacklight::Catalog
  include Hydra::Controller::SearchBuilder
end
