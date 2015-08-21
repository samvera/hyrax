module CurationConcerns
  # Inherit from the host app's ApplicationController
  # This will configure e.g. the layout used by the host
  module ApplicationControllerBehavior
    extend ActiveSupport::Concern

    included do
      helper CurationConcerns::MainAppHelpers

      rescue_from CanCan::AccessDenied do |exception|
        if [:show, :edit, :update, :destroy].include? exception.action
          render 'unauthorized', status: :unauthorized
        else
          redirect_to main_app.root_url, alert: exception.message
        end
      end

      rescue_from ActiveFedora::ObjectNotFoundError do |_exception|
        render file: "#{Rails.root}/public/404", format: :html, status: :not_found, layout: false
      end
    end
  end
end
