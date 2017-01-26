module Hyrax
  # Renders the Help page, terms of use, messages about exporting to Zotero and Mendeley
  class StaticController < ApplicationController
    rescue_from AbstractController::ActionNotFound, with: :render_404
    layout 'homepage'

    def zotero
      respond_to do |format|
        format.html
        format.js { render layout: false }
      end
    end

    def mendeley
      respond_to do |format|
        format.html
        format.js { render layout: false }
      end
    end
  end
end
