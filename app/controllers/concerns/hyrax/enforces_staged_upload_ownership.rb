# frozen_string_literal: true

module Hyrax
  ##
  # Rescues {Hyrax::UploadedFileResolver::OwnershipError}, raised when a
  # request tries to attach staged uploads belonging to another user.
  module EnforcesStagedUploadOwnership
    extend ActiveSupport::Concern

    included do
      rescue_from Hyrax::UploadedFileResolver::OwnershipError,
                  with: :render_staged_upload_ownership_error
    end

    private

    def render_staged_upload_ownership_error(error)
      message = I18n.t('hyrax.uploads.ownership_error')
      Hyrax.logger.error(error.message)

      respond_to do |wants|
        wants.html { redirect_back fallback_location: main_app.root_path, alert: message }
        wants.json { render json: { message: message }, status: :forbidden }
      end
    end
  end
end
