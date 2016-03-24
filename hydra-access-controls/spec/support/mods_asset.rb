class ModsAsset < ActiveFedora::Base
  include Hydra::AccessControls::Embargoable

  # This is how we're associating admin policies with assets.
  # You can associate them however you want, just use the :is_governed_by relationship
  belongs_to :admin_policy, class_name: "Hydra::AdminPolicy", predicate: ActiveFedora::RDF::ProjectHydra.isGovernedBy
end
