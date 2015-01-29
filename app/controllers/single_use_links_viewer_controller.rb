require 'sufia/single_use_error'

class SingleUseLinksViewerController < ApplicationController
  include Sufia::DownloadsControllerBehavior

  skip_before_filter :load_file, except: :download

  class Ability
    include CanCan::Ability

    attr_reader :single_use_link

    def initialize(user, single_use_link)
      @user = user || User.new

      @single_use_link = single_use_link

      can :read, ActiveFedora::Base do |obj|
        single_use_link.valid? && single_use_link.itemId == obj.id && single_use_link.destroy!
      end if single_use_link
    end
  end

  rescue_from Sufia::SingleUseError, with: :render_single_use_error
  rescue_from CanCan::AccessDenied, with: :render_single_use_error
  rescue_from ActiveRecord::RecordNotFound, with: :render_single_use_error

  def download
    raise not_found_exception unless single_use_link.path == sufia.download_path(id: @asset)
    send_content
  end

  def show
    raise not_found_exception unless single_use_link.path == sufia.polymorphic_path(@asset)

    #show the file
    @presenter = presenter

    # create a dowload link that is single use for the user since we do not just want to show metadata we want to access it too
    @su = single_use_link.create_for_path sufia.download_path(id: @asset)
    @download_link = sufia.download_single_use_link_path(@su.downloadKey)
  end

  protected

  def presenter
    Sufia::GenericFilePresenter.new(@asset)
  end

  def authorize_download!
    authorize! :read, asset
  end

  def single_use_link
    @single_use_link ||= SingleUseLink.find_by_downloadKey!(params[:id])
  end

  def not_found_exception
    Sufia::SingleUseError.new('Single-Use Link Not Found')
  end

  def asset
    @asset ||= ActiveFedora::Base.find(single_use_link.itemId)
  end

  def current_ability
    @current_ability ||= SingleUseLinksViewerController::Ability.new current_user, single_use_link
  end
end
