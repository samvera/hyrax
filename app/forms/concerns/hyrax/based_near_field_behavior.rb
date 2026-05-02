# frozen_string_literal: true
module Hyrax
  # Field Behavior for the `based_near` (location) controlled vocabulary form
  # field. The form expects a ControlledVocabularies::Location object as input
  # and produces a hash like those used with accepts_nested_attributes_for.
  #
  # See documentation/forms/field_behaviors.md for the pattern this module
  # follows (why `deserialize` strips and calls `super`, why it's prepended
  # in `inherited`, etc).
  module BasedNearFieldBehavior
    def self.included(descendant)
      descendant.property :based_near_attributes, virtual: true, populator: :based_near_attributes_populator, prepopulator: :based_near_attributes_prepopulator
    end

    # Skipping based_near in deserialize avoids a race condition where it
    # would otherwise end up in an inconsistent state during validation; the
    # field is handled exclusively by the populator on
    # `based_near_attributes`.
    def deserialize(params)
      if params.respond_to?(:delete)
        params.delete('based_near')
        params.delete(:based_near)
      end
      super
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
