# frozen_string_literal: true

module Hyrax
  # Controller concern that sends visitors who land on the bare UUID URL
  # to the resource's display alias when one is set, and stamps a
  # `Turbolinks-Location` header on show responses that were reached via
  # a middleware 301 so the browser address bar updates to the canonical
  # URL the redirect actually targeted. Included into the work and
  # collection show controllers.
  module RedirectToDisplayUrl
    extend ActiveSupport::Concern

    included do
      before_action :redirect_to_display_url, only: :show
      after_action :stamp_turbolinks_location_for_redirected_show, only: :show
    end

    private

    def redirect_to_display_url
      return unless Hyrax.config.redirects_active? && request.format.html?
      return if request.env['hyrax.redirects.rewrote']
      display_path = Hyrax::RedirectsLookup.display_path_for(params[:id])
      return if display_path.blank?
      response.headers['Cache-Control'] = 'no-cache'
      response.headers['Turbolinks-Location'] = display_path
      redirect_to display_path, status: :moved_permanently
    end

    # When Turbolinks chases a redirect via XHR it updates the address
    # bar to the URL it was originally asked to fetch, not the URL the
    # chain ended at. Stamping the current path on every show response
    # tells Turbolinks to use this URL instead of whatever it was
    # originally chasing, which keeps the address bar in sync with the
    # resolver's redirect target.
    def stamp_turbolinks_location_for_redirected_show
      return unless Hyrax.config.redirects_active? && request.format.html?
      return unless response.successful?
      return if request.env['HTTP_TURBOLINKS_REFERRER'].blank?
      response.headers['Turbolinks-Location'] = request.path
    end
  end
end
