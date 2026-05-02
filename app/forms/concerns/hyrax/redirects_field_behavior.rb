# frozen_string_literal: true
module Hyrax
  # Field Behavior for the `redirects` nested-attribute property. The Aliases
  # tab posts under `redirects_attributes`; the populator translates that
  # index-keyed payload into clean `Hyrax::Redirect` entries on the form's
  # `redirects` property and normalizes paths.
  #
  # See documentation/forms/field_behaviors.md for the pattern this module
  # follows (why `deserialize` strips and calls `super`, why it's prepended
  # in `inherited`, etc).
  module RedirectsFieldBehavior
    def self.included(descendant)
      return unless Hyrax.config.redirects_enabled?
      descendant.property :redirects_attributes, virtual: true, populator: :redirects_populator
    end

    def deserialize(params)
      if Hyrax.config.redirects_enabled? && params.respond_to?(:delete)
        params.delete('redirects')
        params.delete(:redirects)
      end
      super
    end

    private

    def redirects_populator(fragment:, **_options)
      return unless respond_to?(:redirects)
      return unless Flipflop.redirects?
      entries = Array(fragment&.values)
                .reject { |row| row['_destroy'].to_s == 'true' || row['path'].to_s.strip.empty? }
                .map do |row|
                  { path: Hyrax::RedirectPathNormalizer.call(row['path']),
                    canonical: row['canonical'].to_s == 'true' }
                end
      self.redirects = entries
    end
  end
end
