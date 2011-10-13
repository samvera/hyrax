# this model exists largely to exercise the default partials for models that don't have their own
#   that is, if an (active)fedora object uses the ModsAsset model, then hydra-head will use partials in views/mods_assets to display those objects
#   however, if an (active)fedora object uses a model without its own partials in the views folder, then hydra-head will use views/catalog/xxx  to display those objects.
# a Fedora object for the Hypatia SET hydra content type
class UsesDefaultPartials < ActiveFedora::Base
  
  has_metadata :name => "descMetadata", :type => Hydra::ModsGenericContent
  
  has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadata

  # adds helpful methods for basic hydra objects.  
  include Hydra::ModelMethods
  
end
