module Hydra
  class AdminPolicy < ActiveFedora::Base

    include Hydra::AdminPolicyBehavior
    include Hydra::AccessControls::Permissions

    property :title, predicate: ::RDF::DC.title do |index|
      index.as :stored_searchable
    end
    property :description, predicate: ::RDF::DC.description do |index|
      index.as :searchable
    end

    # Hack until ActiveFedora supports activeTriples 0.3.0 (then we can just use super)
    def description_with_first
      description_without_first.first
    end
    alias_method_chain :description, :first

    # Hack until ActiveFedora supports activeTriples 0.3.0 (then we can just use super)
    def title_with_first
      title_without_first.first
    end
    alias_method_chain :title, :first

    def license_title=(_)
      Deprecation.warn AdminPolicy, "license_title= has been remove from AdminPolicy. Look at Hydra::Rights instead"
    end

    def license_description=(_)
      Deprecation.warn AdminPolicy, "license_title= has been remove from AdminPolicy. Look at Hydra::Rights instead"
    end

    def license_url=(_)
      Deprecation.warn AdminPolicy, "license_title= has been remove from AdminPolicy. Look at Hydra::Rights instead"
    end
  end
end
