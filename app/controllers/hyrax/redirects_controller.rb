# frozen_string_literal: true

module Hyrax
  # See documentation/redirects.md for the redirects feature.
  class RedirectsController < ApplicationController
    def show
      path = Hyrax::RedirectPathNormalizer.call(params[:alias_path])
      row = Hyrax::RedirectsLookup.find_by_source_path(path)
      raise ActionController::RoutingError, 'Not Found' if row.blank?

      redirect_to row.target_path, status: :moved_permanently
    end
  end
end
