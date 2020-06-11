# frozen_string_literal: true
require 'rdf'
module Vocab
  class FedoraResourceStatus < RDF::StrictVocabulary('http://fedora.info/definitions/1/0/access/ObjState#')
    term :objState, label: 'Object State', type: 'owl:ObjectProperty'
    term :active,   label: 'active',       type: 'owl:NamedIndividual'
    term :deleted,  label: 'deleted',      type: 'owl:NamedIndividual'
    term :inactive, label: 'inactive',     type: 'owl:NamedIndividual'
  end
end
