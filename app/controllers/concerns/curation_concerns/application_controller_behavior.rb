module CurationConcerns
  # Inherit from the host app's ApplicationController
  # This will configure e.g. the layout used by the host
  module ApplicationControllerBehavior
    extend ActiveSupport::Concern

    included do
      helper CurationConcerns::MainAppHelpers

      rescue_from ActiveFedora::ObjectNotFoundError do |exception|
        respond_to do |wants|
          wants.html { render file: "#{Rails.root}/public/404", format: :html, status: :not_found, layout: false }
          wants.json { render_json_response(response_type: :not_found, message: exception.message) }
        end
      end
    end

    def deny_access(exception)
      if current_user && current_user.persisted?
        respond_to do |wants|
          wants.html do
            if [:show, :edit, :create, :update, :destroy].include? exception.action
              render 'curation_concerns/base/unauthorized', status: :unauthorized
            else
              redirect_to main_app.root_url, alert: exception.message
            end
          end
          wants.json { render_json_response(response_type: :forbidden, message: exception.message) }
        end
      else
        session['user_return_to'.freeze] = request.url
        respond_to do |wants|
          wants.html { redirect_to main_app.new_user_session_path, alert: exception.message }
          wants.json { render_json_response(response_type: :unauthorized, message: exception.message) }
        end
      end
    end

    # render a json response for +response_type+

    def render_json_response(response_type: :success, message: nil, options: {})
      json_body = CurationConcerns::API.generate_response_body(response_type: response_type, message: message, options: options)
      render json: json_body, status: response_type
    end
  end
end
