# frozen_string_literal: true

module Hyrax
  ##
  # The Valkyrie model for a single URL redirect entry on a work or collection.
  #
  # A work or collection has zero or more `redirects`. Each entry holds a path
  # (the lookup key for the redirect resolver), a `canonical` flag (at most one
  # entry per record may be true), and an optional `sequence` for display
  # ordering in the admin UI.
  #
  # @example
  #   work.redirects = [
  #     Hyrax::Redirect.new(path: '/handle/12345/678', canonical: false),
  #     Hyrax::Redirect.new(path: '/robs-cat-study', canonical: true, sequence: 0)
  #   ]
  #
  # @see Hyrax::RedirectsController for the resolution path
  class Redirect < Valkyrie::Resource
    attribute :path,      Valkyrie::Types::String
    attribute :canonical, Valkyrie::Types::Bool.default(false)
    attribute :sequence,  Valkyrie::Types::Integer.optional
  end
end
