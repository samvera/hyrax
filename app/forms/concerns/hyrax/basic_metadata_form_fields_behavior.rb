# frozen_string_literal: true
module Hyrax
  module BasicMetadataFormFieldsBehavior
    # Provides compatibility with the behavior of the based_near (location) controlled vocabulary form field.
    # The form expects a ControlledVocabularies::Location object as input and produces a hash like those
    # used with accepts_nested_attributes_for.
    def self.included(descendant)
      descendant.property :based_near_attributes, virtual: true, populator: :based_near_populator, prepopulator: :based_near_prepopulator
    end

    private

    def based_near_populator(fragment:, **_options)
      adds = []
      deletes = []
      fragment.each do |_, h|
        uri = RDF::URI.parse(h["id"]).to_s
        if h["_destroy"] == "true"
          deletes << uri
        else
          adds << uri
        end
      end
      self.based_near = ((model.based_near + adds) - deletes).uniq
    end

    def based_near_prepopulator
      self.based_near = based_near.map do |loc|
        uri = RDF::URI.parse(loc)
        if uri
          Hyrax::ControlledVocabularies::Location.new(uri)
        else
          loc
        end
      end
      based_near << Hyrax::ControlledVocabularies::Location.new if based_near.empty?
    end
  end
end
