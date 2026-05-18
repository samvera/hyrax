# frozen_string_literal: true
module Hyrax
  # Form-side handling for the `based_near` (location) controlled vocabulary
  # field. The form expects a `ControlledVocabularies::Location` object as
  # input and produces a hash like those used with `accepts_nested_attributes_for`.
  #
  # The `deserialize!` override below is the canonical Field Behavior pattern
  # for nested-attribute properties: a module prepended onto every
  # `ResourceForm` subclass that strips its own key from the rewritten params
  # so Reform's `from_hash` doesn't write the raw `_attributes` payload to a
  # same-named property. Calling `super` first lets the chain compose — every
  # Field Behavior runs its own delete, then control falls through to Reform's
  # base `deserialize!` (the `<name>_attributes` rename pass).
  module BasedNearFieldBehavior
    def self.included(descendant)
      descendant.property :based_near_attributes, virtual: true, populator: :based_near_attributes_populator, prepopulator: :based_near_attributes_prepopulator
    end

    # Skipping based_near in deserialize avoids a race condition where it
    # would otherwise end up in an inconsistent state during validation; the
    # field is handled exclusively by the populator on
    # `based_near_attributes`.
    #
    # Override `deserialize!` (not `deserialize`) so the strip runs *after*
    # Reform's `FormBuilderMethods#deserialize!` has renamed
    # `based_near_attributes` to `based_near`, but *before* `from_hash`
    # reads property values from the params. Stripping in `deserialize`
    # would happen before the rename, and the rename would put the key
    # back; `from_hash` would then write raw fragment hashes onto the
    # form's `based_near` field, breaking the populator's contract.
    #
    # Mutate `params` in place — never replace it. Reform's `validate(params)`
    # exposes the same hash via `form.input_params`, and downstream callers
    # (`WorksControllerBehavior#update_valkyrie_work` reading
    # `form.input_params["permissions"]`) read from that exact reference
    # *after* the rename.
    def deserialize!(params)
      result = super
      if result.respond_to?(:delete)
        result.delete('based_near')
        result.delete(:based_near)
      end
      result
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
