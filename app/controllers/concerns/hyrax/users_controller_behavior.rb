module Hyrax::UsersControllerBehavior
  extend ActiveSupport::Concern

  included do
    include Blacklight::SearchContext
    prepend_before_action :find_user, except: [:index, :notifications_number]
    before_action :authenticate_user!, only: [:edit, :update]
    authorize_resource only: [:edit, :update]
    # Catch permission errors
    rescue_from CanCan::AccessDenied, with: :deny_access

    helper Hyrax::TrophyHelper
  end

  def index
    add_breadcrumb t(:'hyrax.controls.home'), root_path
    add_breadcrumb t(:'hyrax.toolbar.admin.menu'), hyrax.admin_path
    add_breadcrumb t(:'hyrax.users.index.title'), request.path
    @presenter = Hyrax::UsersPresenter.new(query: params[:uq],
                                           authentication_key: Devise.authentication_keys.first)
  end

  # Display user profile
  def show
    @presenter = Hyrax::UserProfilePresenter.new(@user, current_ability)
  end

  # Display form for users to edit their profile information
  def edit
    @trophies = Hyrax::TrophyPresenter.find_by_user(@user)
  end

  # Process changes from profile form
  def update
    if params[:user]
      @user.attributes = user_params
      @user.populate_attributes if update_directory?
    end

    unless @user.save
      redirect_to hyrax.edit_profile_path(@user.to_param), alert: @user.errors.full_messages
      return
    end
    # TODO: this should be moved to TrophiesController
    params.keys.select { |k, _v| k.starts_with? 'remove_trophy_' }.each do |smash_trophy|
      smash_trophy = smash_trophy.sub(/^remove_trophy_/, '')
      current_user.trophies.where(work_id: smash_trophy).destroy_all
    end
    UserEditProfileEventJob.perform_later(@user)
    redirect_to hyrax.profile_path(@user.to_param), notice: "Your profile has been updated"
  end

  def update_directory?
    ['1', 'true'].include? params[:user][:update_directory]
  end

  def notifications_number
    @notify_number = 0
    return if action_name == "index" && controller_name == "mailbox"
    return unless user_signed_in?
    @notify_number = current_user.mailbox.inbox(unread: true).count
  end

  protected

    def user_params
      params.require(:user).permit(:avatar, :facebook_handle, :twitter_handle,
                                   :googleplus_handle, :linkedin_handle, :remove_avatar, :orcid)
    end

    def find_user
      @user = User.from_url_component(params[:id])
      redirect_to root_path, alert: "User '#{params[:id]}' does not exist" if @user.nil?
    end

    def deny_access(_exception)
      redirect_to hyrax.profile_path(@user.to_param), alert: "Permission denied: cannot access this page."
    end
end
