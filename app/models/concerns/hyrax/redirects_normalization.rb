# frozen_string_literal: true

module Hyrax
  # Normalizes redirect path entries on assignment so every write path —
  # form submissions, console writes, importers, change-set saves —
  # produces normalized data. Read-side consumers can trust the persisted
  # shape and skip their own normalization.
  #
  # Included next to Hyrax::Schema(:redirects) on Hyrax::Work and
  # Hyrax::PcdmCollection. The override sits on Valkyrie's set_value
  # primitive so it fires under both flex modes (the simple schema's
  # generated setter and the m3 singleton-class setter both route through
  # set_value).
  #
  # See documentation/redirects.md.
  module RedirectsNormalization
    extend ActiveSupport::Concern

    def set_value(key, value)
      value = normalize_redirects(value) if key.to_sym == :redirects
      super
    end

    private

    def normalize_redirects(value)
      Array(value).map { |entry| normalize_entry(entry) }
    end

    def normalize_entry(entry)
      return entry unless entry.is_a?(Hash)
      normalized = entry.dup
      path_key = normalized.key?(:path) ? :path : 'path'
      normalized[path_key] = Hyrax::RedirectPathNormalizer.call(normalized[path_key])
      normalized
    end
  end
end
