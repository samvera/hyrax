# frozen_string_literal: true

module Hyrax
  # See documentation/redirects.md for the redirects feature.
  #
  # Wired up as a catch-all route in the host application's `config/routes.rb`
  # (see the install generator). Serves any path not claimed by an earlier
  # route when the feature is active.
  class RedirectsController < ApplicationController
    def show
      row = Hyrax::RedirectsLookup.find_row(params[:alias_path])
      raise ActionController::RoutingError, 'Not Found' if row.blank?

      if row.is_display_url?
        dispatch_in_place(row)
      else
        redirect_to row.to_path, status: :moved_permanently
      end
    end

    private

    # The visited path IS the display URL — render the resource's show
    # page in place at the visited path. Use `recognize_path` to find
    # the underlying curation-concern controller for the permalink, then
    # dispatch the same request to it. Setting
    # `request.env['hyrax.redirects.dispatched']` signals
    # `Hyrax::RedirectToDisplayUrl` to skip its own redirect check on
    # the inner controller's show action — otherwise the inner show
    # would see the visited path, find the same row, and try to redirect
    # back to itself.
    def dispatch_in_place(row)
      info = Rails.application.routes.recognize_path(row.permalink_path)
      controller_class = "#{info[:controller].camelize}Controller".constantize
      request.path_parameters = info
      request.env['hyrax.redirects.dispatched'] = true
      controller_class.dispatch(info[:action], request, response)
      # The inner controller wrote into the shared `response`; mark the outer
      # action as performed so Rails skips its own implicit_render lookup.
      self.response_body = response.body
    end
  end
end
