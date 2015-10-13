module CurationConcerns::HasRepresentative
  extend ActiveSupport::Concern

  included do
    belongs_to :representative,
               predicate: ::RDF::URI('http://opaquenamespace.org/ns/hydra/representative'),
               class_name: 'ActiveFedora::Base'
  end
end
