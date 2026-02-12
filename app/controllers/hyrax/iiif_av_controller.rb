# frozen_string_literal: true

module Hyrax
  class IiifAvController < ApplicationController
    include Blacklight::Base
    include Blacklight::AccessControls::Catalog

    def content
      file_set_id = params[:id]
      label = params[:label]
      if request.head?
        return head :ok if valid_token? || can?(:read, params[:id])

        head :unauthorized
      else
        return head :unauthorized unless presenter

        redirect_to hyrax.download_path(file_set_id, file: label, locale: nil)
      end
    end

    def auth_token
      return head :unauthorized unless can? :read, params[:id]
      response.set_header('Content-Security-Policy', 'frame-ancestors *')
      render html: auth_token_html_response(generate_auth_token)
    end

    # This route is meant to be used with devise's `after_sign_in_path_for` as part of the IIIF Auth flow
    # See the override of `after_sign_in_path_for` in Hyrax::IiifAv::AuthControllerBehavior
    def sign_in
      render inline: "<html><head><script>window.close();</script></head><body></body></html>".html_safe
    end

    private

    def generate_auth_token
      # This is the same method used by ActiveRecord::SecureToken
      token = SecureRandom.base58(24)
      Rails.cache.write("iiif_auth_token-#{token}", params[:id])
      token
    end

    def auth_token_html_response(token)
      message = { messageId: params[:messageId], accessToken: token }
      origin = Rails::Html::FullSanitizer.new.sanitize(params[:origin])
      "<html><body><script>window.parent.postMessage(#{message.to_json}, \"#{origin}\");</script></body></html>".html_safe # rubocop:disable Rails/OutputSafety
    end

    def valid_token?
      auth_token = request.headers['Authorization']&.sub('Bearer ', '')&.strip
      resource_id = Rails.cache.read("iiif_auth_token-#{auth_token}")
      params[:id] == resource_id
    end

    # Override of Blacklight::RequestBuilders
    def search_builder_class
      Hyrax::FileSetSearchBuilder
    end

    def presenter
      @presenter ||= begin
        _, document_list = search_results(params)
        curation_concern = document_list.first
        return nil unless curation_concern
        # Use the show presenter configured in the FileSetsController
        Hyrax::FileSetsController.show_presenter.new(curation_concern, current_ability, request)
      end
    end
  end
end
