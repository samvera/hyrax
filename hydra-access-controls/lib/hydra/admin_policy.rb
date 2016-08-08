module Hydra
  class AdminPolicy < ActiveFedora::Base

    include Hydra::AdminPolicyBehavior
    include Hydra::AccessControls::Permissions

    property :title, predicate: ::RDF::Vocab::DC.title do |index|
      index.as :stored_searchable
    end
    property :description, predicate: ::RDF::Vocab::DC.description do |index|
      index.as :searchable
    end

    def description
      super.first
    end

    def title
      super.first
    end
  end
end
