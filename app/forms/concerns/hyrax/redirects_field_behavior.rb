# frozen_string_literal: true

module Hyrax
  # Form-side handling for the `redirects` nested-attribute field.
  #
  # Submitted form payloads arrive under `redirects_attributes` and are
  # turned into plain hashes (the persisted shape — see
  # `config/metadata/redirects.yaml`, `type: hash`) by the populator.
  # The form partial wraps each persisted hash in a `Hyrax::Redirect`
  # value object at render time so the view can call `.path` and
  # `.display_url`.
  #
  # The `deserialize!` override removes the renamed `redirects` key
  # before Reform's `from_hash` runs, so the form's `redirects`
  # property is written exclusively by the populator. See
  # `Hyrax::BasedNearFieldBehavior` for the parallel pattern.
  #
  # ## Feature gating
  #
  # `self.included` runs at class load time and uses the structural
  # gate `Hyrax.config.redirects_enabled?`. The runtime Flipflop
  # check isn't meaningful here because the form class is being
  # defined, not handling a request.
  #
  # All runtime-side methods (`deserialize!`, populator, prepopulator)
  # delegate to `Hyrax.config.redirects_active?`, the two-gate
  # combinator (`redirects_enabled? && Flipflop.redirects?`). Calling
  # `Flipflop.redirects?` directly is unsafe when the config is off
  # because the feature isn't registered in that case.
  module RedirectsFieldBehavior
    def self.included(descendant)
      return unless Hyrax.config.redirects_enabled?
      # Declare the radio-group scalar before redirects_attributes so Reform
      # deserializes it first; the populator reads its value while building
      # per-row entries.
      descendant.property :redirects_display_url_index, virtual: true
      descendant.property :redirects_attributes,
                          virtual: true,
                          populator: :redirects_attributes_populator
    end

    # Reform's FormBuilderMethods rewrites `redirects_attributes` →
    # `redirects` before `from_hash` runs. Strip the renamed key so
    # the populator on `redirects_attributes` is the single entry
    # point for form-driven writes.
    def deserialize!(params)
      result = super
      if Hyrax.config.redirects_active? && result.respond_to?(:delete)
        result.delete('redirects')
        result.delete(:redirects)
      end
      result
    end

    private

    # Builds plain hashes (the persisted shape) from the submitted
    # `redirects_attributes` payload. Drops rows marked for destruction
    # or with a blank path. Normalizes paths up-front so the validator
    # sees normalized form (so DSpace-style pasted URLs validate cleanly).
    #
    # When `redirects_display_url_index` is set (form-driven radio
    # group), the matching original-index row gets `display_url: true`
    # and all other rows get false. When absent (Bulkrax import path),
    # the row's own `display_url` value is honored.
    def redirects_attributes_populator(fragment:, **_options)
      return unless respond_to?(:redirects)
      return unless Hyrax.config.redirects_active?
      pairs = redirects_fragment_pairs(fragment)
      self.redirects = pairs.sort_by { |k, _row| k.to_i }
                            .map { |k, row| redirects_entry_from(k, row) }
                            .compact
    end

    def redirects_fragment_pairs(fragment)
      return {} if fragment.nil?
      fragment.respond_to?(:to_unsafe_h) ? fragment.to_unsafe_h : fragment.to_h
    end

    def redirects_entry_from(key, row)
      row = row.respond_to?(:to_unsafe_h) ? row.to_unsafe_h : row
      return nil if row['_destroy'].to_s == 'true' || row['path'].to_s.strip.empty?
      { 'path' => Hyrax::RedirectPathNormalizer.call(row['path']),
        'display_url' => redirects_display_url_flag_for(key, row) }
    end

    def redirects_display_url_flag_for(key, row)
      if redirects_display_url_index.nil?
        row['display_url'].to_s == 'true'
      else
        key.to_s == redirects_display_url_index.to_s
      end
    end
  end
end
