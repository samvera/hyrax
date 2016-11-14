require 'rdf'
module Vocab
  class FedoraResourceStatus < RDF::StrictVocabulary('http://fedora.info/definitions/1/0/access/ObjState#')
    term :objState, label: 'Object State'.freeze, type: 'owl:ObjectProperty'.freeze
    term :active,   label: 'active'.freeze,       type: 'owl:NamedIndividual'.freeze
    term :deleted,  label: 'deleted'.freeze,      type: 'owl:NamedIndividual'.freeze
    term :inactive, label: 'inactive'.freeze,     type: 'owl:NamedIndividual'.freeze
  end
end
