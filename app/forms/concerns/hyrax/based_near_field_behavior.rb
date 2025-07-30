# frozen_string_literal: true
module Hyrax
  module BasedNearFieldBehavior
    # Provides compatibility with the behavior of the based_near (location) controlled vocabulary form field.
    # The form expects a ControlledVocabularies::Location object as input and produces a hash like those
    # used with accepts_nested_attributes_for.
    def self.included(descendant)
      descendant.property :based_near_attributes, virtual: true, populator: :based_near_attributes_populator, prepopulator: :based_near_attributes_prepopulator
    end

    # there is a race condition during validation that leaves the based_near field in an inconsistent state.
    # we skip the unedited based_near for validation and only handle it during attribute population
    def deserialize(params)
      params = deserialize!(params)
      deserializer.new(self).from_hash(params.except('based_near'))
    end

    private

    def based_near_attributes_populator(fragment:, **_options)
      return unless respond_to?(:based_near)
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

    def based_near_attributes_prepopulator
      return unless respond_to?(:based_near)
      self.based_near = based_near&.map do |loc|
        uri = RDF::URI.parse(loc)
        if uri
          Hyrax::ControlledVocabularies::Location.new(uri)
        else
          loc
        end
      end
      self.based_near ||= []
      self.based_near << Hyrax::ControlledVocabularies::Location.new if self.based_near.blank?
    end
  end
end
