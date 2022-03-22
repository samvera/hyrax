# frozen_string_literal: true
module Hyrax
  module ControlledVocabularies
    class Location < ActiveTriples::Resource
      configure rdf_label: ::RDF::Vocab::GEONAMES.name

      include ResourceLabelCaching

      # Return a tuple of url & label
      def solrize
        label = full_label || rdf_label.first.to_s
        return [rdf_subject.to_s] if label.blank? || label == rdf_subject.to_s
        [rdf_subject.to_s, { label: "#{label}$#{rdf_subject}" }]
      end

      def full_label
        Hyrax::LocationService.new.full_label(rdf_subject.to_s)
      end
    end
  end
end
