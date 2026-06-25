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
        redirect_to with_locale(row.to_path), status: :moved_permanently
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
      info[:locale] = params[:locale] if params[:locale].present?
      controller_class = "#{info[:controller].camelize}Controller".constantize
      request.path_parameters = info
      request.env['hyrax.redirects.dispatched'] = true
      controller_class.dispatch(info[:action], request, response)
      # The inner controller wrote into the shared `response`; mark the outer
      # action as performed so Rails skips its own implicit_render lookup.
      self.response_body = response.body
    end

    # Carry the visitor's requested locale (set by Hyrax::Controller#set_locale
    # from `params[:locale]`) across the 301 so the destination page renders in
    # the same language. Appended as `?locale=<value>` so this works whether the
    # host app uses path-prefix or query-string locales. The locale value is
    # URL-encoded via Rack::Utils.build_query so attacker-controlled chars in
    # params[:locale] can't inject extra query params into the Location header.
    def with_locale(path)
      return path if params[:locale].blank?
      separator = path.include?('?') ? '&' : '?'
      "#{path}#{separator}#{Rack::Utils.build_query(locale: params[:locale])}"
    end
  end
end
