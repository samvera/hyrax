# frozen_string_literal: true

module Hyrax
  # Single point of truth for read-side queries against the
  # `hyrax_redirect_paths` table. The unique index on `from_path` makes
  # both lookups (`.find_row` and `.taken?`) indexed equality checks on a
  # small derived table — sub-millisecond against any reasonable load.
  #
  # See documentation/redirects.md.
  class RedirectsLookup
    # Returns true if any row exists with the given `from_path`, optionally
    # excluding rows owned by `except_id`. Used by `Hyrax::RedirectValidator`
    # at form-submit time to surface "this alias is already in use" before
    # the DB unique index would reject the insert.
    #
    # @param path [String] the alias to check, normalized or not
    # @param except_id [String, nil] resource_id to exclude from the check
    # @return [Boolean]
    def self.taken?(path, except_id: nil)
      new(path, except_id: except_id).taken?
    end

    # Returns the `Hyrax::RedirectPath` row matching the given `from_path`,
    # or nil when no row matches. Used by request-time resolvers
    # (`Hyrax::RedirectsController` and the `Hyrax::RedirectToDisplayUrl`
    # before_action) to decide whether the visited path triggers a
    # redirect or in-process dispatch.
    #
    # @param path [String] the visited path, normalized or not
    # @return [Hyrax::RedirectPath, nil]
    def self.find_row(path)
      normalized = Hyrax::RedirectPathNormalizer.call(path)
      return nil if normalized.blank?
      Hyrax::RedirectPath.find_by(from_path: normalized)
    end

    # Returns the `from_path` of the row marked as the resource's display
    # URL, or nil when no row is marked.
    #
    # @param resource_id [String]
    # @return [String, nil]
    def self.display_path_for(resource_id)
      return nil if resource_id.blank?
      Hyrax::RedirectPath.where(resource_id: resource_id, is_display_url: true).limit(1).pick(:from_path)
    end

    def initialize(path, except_id: nil)
      @path = Hyrax::RedirectPathNormalizer.call(path)
      @except_id = except_id
    end

    def taken?
      return false if @path.blank?
      scope = Hyrax::RedirectPath.where(from_path: @path)
      scope = scope.where.not(resource_id: @except_id) if @except_id.present?
      scope.exists?
    end
  end
end
