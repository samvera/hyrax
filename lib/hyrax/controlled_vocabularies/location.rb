module Hyrax
  module ControlledVocabularies
    class Location < ActiveTriples::Resource
      configure rdf_label: ::RDF::Vocab::GEONAMES.name

      # Return a tuple of url & label
      def solrize(full_label)
        return [rdf_subject.to_s] if rdf_label.first.to_s.blank? || rdf_label.first.to_s == rdf_subject.to_s
        [rdf_subject.to_s, { label: "#{full_label}$#{rdf_subject}" }]
      end
    end
  end
end
