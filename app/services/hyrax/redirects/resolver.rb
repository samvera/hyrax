# frozen_string_literal: true

module Hyrax
  module Redirects
    # Resolves a normalized alias path to one of three outcomes:
    #
    # - {render_path: '/the/visited/alias'} — show page should render in place at the visited path
    # - {redirect_to: '/some/path'}         — caller should 301 to the given path
    # - nil                                  — no redirect applies; caller should 404
    #
    # The visited row's `target_path` carries the decision: `nil` means
    # "render in place at the visited source_path"; otherwise it points
    # at the path the caller should 301 to. One indexed DB lookup per
    # request; no second query, no Solr.
    class Resolver
      def self.call(path)
        new(path).call
      end

      def initialize(path)
        @path = path
      end

      def call
        return nil if @path.blank?
        row = Hyrax::RedirectsLookup.find_row(@path)
        return nil if row.nil?
        return { render_path: @path } if row.target_path.nil?
        { redirect_to: row.target_path }
      rescue ActiveRecord::StatementInvalid => e
        Hyrax.logger.warn "[redirects] resolver failed for #{@path.inspect}: #{e.message}"
        nil
      end
    end
  end
end
