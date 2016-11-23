module CurationConcerns
  # Inherit from the host app's ApplicationController
  # This will configure e.g. the layout used by the host
  module ApplicationControllerBehavior
    extend ActiveSupport::Concern

    included do
      helper CurationConcerns::MainAppHelpers
      rescue_from ActiveFedora::ObjectNotFoundError, with: :not_found_response
      rescue_from Blacklight::Exceptions::InvalidSolrID, with: :not_found_response
    end

    def render_404
      # use standard, possibly locally overridden, 404.html file. Even for
      # possibly non-html formats, this is consistent with what Rails does
      # on raising an ActiveRecord::RecordNotFound. Rails.root IS needed
      # for it to work under testing, without worrying about CWD.
      render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
    end

    # Called by Hydra::Controller::ControllerBehavior when CanCan::AccessDenied is caught
    # @param [CanCan::AccessDenied] exception error to handle
    def deny_access(exception)
      # For the JSON message, we don't want to display the default CanCan messages,
      # just custom Hydra messages such as "This item is under embargo.", etc.
      json_message = exception.message if exception.is_a? Hydra::AccessDenied
      if current_user && current_user.persisted?
        respond_to do |wants|
          wants.html do
            if [:show, :edit, :create, :update, :destroy].include? exception.action
              render 'curation_concerns/base/unauthorized', status: :unauthorized
            else
              redirect_to main_app.root_url, alert: exception.message
            end
          end
          wants.json { render_json_response(response_type: :forbidden, message: json_message) }
        end
      else
        session['user_return_to'.freeze] = request.url
        respond_to do |wants|
          wants.html { redirect_to main_app.new_user_session_path, alert: exception.message }
          wants.json { render_json_response(response_type: :unauthorized, message: json_message) }
        end
      end
    end

    # render a json response for +response_type+

    def render_json_response(response_type: :success, message: nil, options: {})
      json_body = CurationConcerns::API.generate_response_body(response_type: response_type, message: message, options: options)
      render json: json_body, status: response_type
    end

    private

      def not_found_response(_exception)
        respond_to do |wants|
          wants.json { render_json_response(response_type: :not_found) }
          # default to HTML response, even for other non-HTML formats we don't
          # neccesarily know about, seems to be consistent with what Rails4 does
          # by default with uncaught ActiveRecord::RecordNotFound in production
          wants.any do
            render_404
          end
        end
      end
  end
end
