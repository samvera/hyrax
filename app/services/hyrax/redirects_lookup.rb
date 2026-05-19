# frozen_string_literal: true

module Hyrax
  # Single point of truth for "is this redirect path already taken?" and
  # for the request-time resolver lookup. Backed by the
  # `hyrax_redirect_paths` table, which has a unique index on
  # `source_path` for both correctness (rejects duplicates at insert
  # time) and lookup speed (B-tree equality on a small derived table).
  #
  # See documentation/redirects.md.
  class RedirectsLookup
    def self.taken?(path, except_id: nil)
      new(path, except_id: except_id).taken?
    end

    def self.find_row(path)
      return nil if path.blank?
      Hyrax::RedirectPath.find_by(source_path: path)
    end

    # Returns the source_path of the row marked as the resource's
    # display URL, or nil when no row is marked. Used by show-page
    # helpers (canonical link, UUID-URL-to-display-alias redirect),
    # not by the request-time resolver.
    def self.display_path_for(resource_id)
      return nil if resource_id.blank?
      Hyrax::RedirectPath.where(resource_id: resource_id, display_url: true).limit(1).pick(:source_path)
    end

    def initialize(path, except_id: nil)
      @path = Hyrax::RedirectPathNormalizer.call(path)
      @except_id = except_id
    end

    def taken?
      return false if @path.blank?
      scope = Hyrax::RedirectPath.where(source_path: @path)
      scope = scope.where.not(resource_id: @except_id) if @except_id.present?
      scope.exists?
    end
  end
end
