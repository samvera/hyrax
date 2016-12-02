require 'oauth'

module Sufia
  module API
    # Adds the ability to authenticate against Zotero's OAuth endpoint
    class ZoteroController < ApplicationController
      before_action :authenticate_user!
      before_action :authorize_user!
      before_action :validate_params, only: :callback

      def initiate
        request_token = client.get_request_token(oauth_callback: callback_url)
        session[:request_token] = request_token
        current_user.zotero_token = request_token
        current_user.save
        redirect_to request_token.authorize_url(identity: '1', oauth_callback: callback_url)
      rescue OAuth::Unauthorized
        redirect_to root_url, alert: 'Invalid Zotero client key pair'
      end

      def callback
        access_token = current_token.get_access_token(oauth_verifier: params['oauth_verifier'])
        # parse userID and API key out of token and store in user instance
        current_user.zotero_userid = access_token.params[:userID]
        current_user.save
        Sufia::Arkivo::CreateSubscriptionJob.perform_later(current_user)
        redirect_to sufia.profile_path(current_user), notice: 'Successfully connected to Zotero!'
      rescue OAuth::Unauthorized
        redirect_to sufia.edit_profile_path(current_user.to_param), alert: 'Please re-authenticate with Zotero'
      ensure
        current_user.zotero_token = nil
        current_user.save
      end

      private

        def authorize_user!
          authorize! :create, Sufia.primary_work_type
        rescue CanCan::AccessDenied
          return redirect_to root_url, alert: 'You are not authorized to perform this operation'
        end

        def validate_params
          return redirect_to sufia.edit_profile_path(current_user.to_param), alert: "Malformed request from Zotero" if params[:oauth_token].blank? || params[:oauth_verifier].blank?
          return redirect_to sufia.edit_profile_path(current_user.to_param), alert: "You have not yet connected to Zotero" if !current_token || current_token.params[:oauth_token] != params[:oauth_token]
        end

        def client
          ::OAuth::Consumer.new(Sufia::Zotero.config['client_key'], Sufia::Zotero.config['client_secret'], options)
        end

        def current_token
          current_user.zotero_token
        end

        def callback_url
          "#{request.base_url}/api/zotero/callback"
        end

        def options
          {
            site: 'https://www.zotero.org',
            scheme: :query_string,
            http_method: :get,
            request_token_path: '/oauth/request',
            access_token_path: '/oauth/access',
            authorize_path: '/oauth/authorize'
          }
        end
    end
  end
end
