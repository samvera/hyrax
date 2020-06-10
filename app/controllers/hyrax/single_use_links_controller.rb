# frozen_string_literal: true
module Hyrax
  class SingleUseLinksController < ApplicationController
    include Blacklight::SearchHelper
    class_attribute :show_presenter
    self.show_presenter = Hyrax::SingleUseLinkPresenter
    before_action :authenticate_user!
    before_action :authorize_user!
    # Catch permission errors
    rescue_from Hydra::AccessDenied, CanCan::AccessDenied, with: :deny_link_access

    def deny_link_access(exception)
      if current_user&.persisted?
        redirect_to main_app.root_url, alert: "You do not have sufficient privileges to create links to this document"
      else
        session["user_return_to"] = request.url
        redirect_to new_user_session_url, alert: exception.message
      end
    end

    def create_download
      @su = SingleUseLink.create item_id: params[:id], path: hyrax.download_path(id: params[:id])
      render plain: hyrax.download_single_use_link_url(@su.download_key)
    end

    def create_show
      @su = SingleUseLink.create(item_id: params[:id], path: asset_show_path)
      render plain: hyrax.show_single_use_link_url(@su.download_key)
    end

    def index
      links = SingleUseLink.where(item_id: params[:id]).map { |link| show_presenter.new(link) }
      render partial: 'hyrax/file_sets/single_use_link_rows', locals: { single_use_links: links }
    end

    def destroy
      SingleUseLink.find_by_download_key(params[:link_id]).destroy
      head :ok
    end

    private

    def authorize_user!
      authorize! :edit, params[:id]
    end

    def asset_show_path
      polymorphic_path([main_app, fetch(params[:id]).last])
    end
  end
end
