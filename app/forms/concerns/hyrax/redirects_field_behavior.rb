# frozen_string_literal: true

module Hyrax
  # Form-side handling for the `redirects` nested-attribute field.
  #
  # Submitted form payloads arrive under `redirects_attributes` and are
  # turned into plain hashes (the persisted shape — see
  # `config/metadata/redirects.yaml`, `type: hash`) by the populator.
  # On render, the prepopulator wraps each persisted hash in a
  # `Hyrax::Redirect` value object so the view can call `.path` /
  # `.canonical` / `.sequence`.
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
      descendant.property :redirects_attributes,
                          virtual: true,
                          populator: :redirects_attributes_populator,
                          prepopulator: :redirects_attributes_prepopulator
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
    # or with a blank path. Normalizes paths to the canonical form
    # stored in the uniqueness ledger.
    def redirects_attributes_populator(fragment:, **_options)
      return unless respond_to?(:redirects)
      return unless Hyrax.config.redirects_active?
      entries = Array(fragment&.values)
                .reject { |row| row['_destroy'].to_s == 'true' || row['path'].to_s.strip.empty? }
                .each_with_index.map do |row, i|
        { 'path' => Hyrax::RedirectPathNormalizer.call(row['path']),
          'canonical' => row['canonical'].to_s == 'true',
          'sequence' => row['sequence'].presence&.to_i || i }
      end
      self.redirects = entries
    end

    # Wraps each persisted hash in a `Hyrax::Redirect` value object for
    # the form view. Mirrors how `BasedNearFieldBehavior` hydrates URI
    # strings into `ControlledVocabularies::Location` instances.
    def redirects_attributes_prepopulator
      return unless respond_to?(:redirects)
      return unless Hyrax.config.redirects_active?
      self.redirects = Array(redirects).map { |entry| Hyrax::Redirect.wrap(entry) }
    end
  end
end
