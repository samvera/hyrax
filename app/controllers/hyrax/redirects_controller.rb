# frozen_string_literal: true

module Hyrax
  # See documentation/redirects.md for the redirects feature.
  class RedirectsController < ApplicationController
    def show
      path = Hyrax::RedirectPathNormalizer.call(params[:alias_path])
      redirect_path = Hyrax::RedirectPath.find_by(from_path: path)
      raise ActionController::RoutingError, 'Not Found' if redirect_path.blank?

      if redirect_path.is_display_url?
        begin
          info = Rails.application.routes.recognize_path(redirect_path.permalink_path)
          controller = "#{info[:controller].camelize}Controller".constantize
          request.path_parameters = info.merge(is_redirect: true)
          controller.dispatch(info[:action], request, response)
          # rescue StandardError => e
          # raise ActionController::RoutingError, e.message
        end
      else
        redirect_to redirect_path.to_path, status: :moved_permanently
      end
    end
  end
end
