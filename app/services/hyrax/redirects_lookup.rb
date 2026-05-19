# frozen_string_literal: true

module Hyrax
  # Single point of truth for "is this redirect path already taken?" and
  # for the request-time resolver lookups. Backed by the
  # `hyrax_redirect_paths` table, which has a unique index on `path` for
  # both correctness (rejects duplicates at insert time) and lookup speed
  # (B-tree equality on a small derived table).
  #
  # See documentation/redirects.md.
  class RedirectsLookup
    def self.taken?(path, except_id: nil)
      new(path, except_id: except_id).taken?
    end

    def self.find_row(path)
      return nil if path.blank?
      Hyrax::RedirectPath.find_by(path: path)
    end

    def self.display_path_for(resource_id)
      return nil if resource_id.blank?
      Hyrax::RedirectPath.where(resource_id: resource_id, display_url: true).limit(1).pick(:path)
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
