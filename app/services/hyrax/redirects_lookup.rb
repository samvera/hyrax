# frozen_string_literal: true

module Hyrax
  # Lookups against the `hyrax_redirect_paths` table.
  #
  # See documentation/redirects.md.
  class RedirectsLookup
    def self.taken?(path, except_id: nil)
      new(path, except_id: except_id).taken?
    end

    def self.find_by_source_path(path)
      new(path).find_by_source_path
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

    def find_by_source_path
      return nil if @path.blank?
      Hyrax::RedirectPath.find_by(source_path: @path)
    end
  end
end
