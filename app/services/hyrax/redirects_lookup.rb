# frozen_string_literal: true

module Hyrax
  # Single point of truth for "is this redirect path already taken?".
  # Backed by the `hyrax_redirect_paths` table, which has a unique index on
  # `path` for both correctness (rejects duplicates at insert time) and
  # lookup speed (B-tree equality on a small derived table).
  #
  # See documentation/redirects.md.
  class RedirectsLookup
    def self.taken?(path, except_id: nil)
      new(path, except_id: except_id).taken?
    end

    def initialize(path, except_id: nil)
      @path = Hyrax::RedirectPathNormalizer.call(path)
      @except_id = except_id
    end

    def taken?
      return false if @path.blank?
      scope = Hyrax::RedirectPath.where(path: @path)
      scope = scope.where.not(resource_id: @except_id) if @except_id.present?
      scope.exists?
    end
  end
end
