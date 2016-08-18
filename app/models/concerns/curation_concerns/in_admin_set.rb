module CurationConcerns
  module InAdminSet
    extend ActiveSupport::Concern

    included do
      belongs_to :admin_set, predicate: ::RDF::Vocab::DC.isPartOf
    end
  end
end
