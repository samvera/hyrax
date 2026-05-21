# frozen_string_literal: true

module Hyrax
  # Controller concern that sends visitors who land on a path with a
  # redirect-table row pointing elsewhere to that other path. Included on
  # work and collection show controllers via the curation-concerns
  # behavior modules.
  #
  # Two request shapes hit this concern:
  #
  # - Direct UUID URL visits (`/concern/generic_works/<uuid>`) — Rails
  #   routes natively to the show action. If the resource has a display
  #   alias, the row keyed on the UUID URL has `to_path` pointing at the
  #   alias, and the before_action 301s the visitor there.
  # - In-process dispatches from `Hyrax::RedirectsController` — the
  #   resolver finds a display-URL row and re-dispatches the request
  #   through `recognize_path` + `controller.dispatch`. To avoid the
  #   before_action firing again on the same logical request, the
  #   resolver sets `request.env['hyrax.redirects.dispatched'] = true`
  #   before dispatching; this concern checks the same env key and
  #   no-ops when set.
  #
  # See documentation/redirects.md.
  module RedirectToDisplayUrl
    extend ActiveSupport::Concern

    included do
      before_action :redirect_to_display_url_if_needed, only: :show
    end

    private

    def redirect_to_display_url_if_needed
      return if request.env['hyrax.redirects.dispatched']
      return unless Hyrax.config.redirects_active?
      row = Hyrax::RedirectsLookup.find_row(request.path)
      return if row.blank?
      return if row.to_path == request.path
      redirect_to with_locale(row.to_path), status: :moved_permanently
    end

    # Carry the visitor's requested locale (set by Hyrax::Controller#set_locale
    # from `params[:locale]`) across the 301 so the destination page renders in
    # the same language. Appended as `?locale=<value>` so this works whether the
    # host app uses path-prefix or query-string locales.
    def with_locale(path)
      return path if params[:locale].blank?
      separator = path.include?('?') ? '&' : '?'
      "#{path}#{separator}locale=#{params[:locale]}"
    end
  end
end
