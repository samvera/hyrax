module Sufia::UsersControllerBehavior
  extend ActiveSupport::Concern

  included do
    include Blacklight::SearchContext
    layout "sufia-one-column"
    prepend_before_action :find_user, except: [:index, :search, :notifications_number]
    before_action :authenticate_user!, only: [:edit, :update, :follow, :unfollow, :toggle_trophy]
    before_action :user_not_current_user, only: [:follow, :unfollow]
    authorize_resource only: [:edit, :update, :toggle_trophy]
    # Catch permission errors
    rescue_from CanCan::AccessDenied, with: :deny_access
  end

  def index
    query = params[:uq].blank? ? nil : "%" + params[:uq].downcase + "%"
    base = User.where(*base_query)
    unless query.blank?
      base = base.where("#{Devise.authentication_keys.first} like lower(?) OR display_name like lower(?)", query, query)
    end
    @users = base.references(:trophies).order(sort_value).page(params[:page]).per(10)

    respond_to do |format|
      format.html
      format.json { render json: @users.to_json }
    end
  end

  # Display user profile
  def show
    @events = if @user.respond_to? :profile_events
                @user.profile_events(100)
              else
                []
              end
    @trophies = @user.trophy_works
    @followers = @user.followers
    @following = @user.all_following
  end

  # Display form for users to edit their profile information
  def edit
    @trophies = @user.trophy_works
  end

  # Process changes from profile form
  def update
    if params[:user]
      @user.attributes = user_params
      @user.populate_attributes if update_directory?
    end

    unless @user.save
      redirect_to sufia.edit_profile_path(@user.to_param), alert: @user.errors.full_messages
      return
    end
    # TODO: this should be moved to TrophiesController
    params.keys.select { |k, _v| k.starts_with? 'remove_trophy_' }.each do |smash_trophy|
      smash_trophy = smash_trophy.sub(/^remove_trophy_/, '')
      current_user.trophies.where(work_id: smash_trophy).destroy_all
    end
    UserEditProfileEventJob.perform_later(@user)
    redirect_to sufia.profile_path(@user.to_param), notice: "Your profile has been updated"
  end

  def update_directory?
    ['1', 'true'].include? params[:user][:update_directory]
  end

  def toggle_trophy
    work_id = params[:work_id]
    unless current_user.can? :edit, work_id
      redirect_to root_path, alert: "You do not have permissions to the work"
      return false
    end
    t = current_user.trophies.where(work_id: work_id).first
    if t
      t.destroy
      return false if t.persisted?
    else
      t = current_user.trophies.create(work_id: work_id)
      return false unless t.persisted?
    end
    render json: t
  end

  # Follow a user
  def follow
    unless current_user.following?(@user)
      current_user.follow(@user)
      UserFollowEventJob.perform_later(current_user, @user)
    end
    redirect_to sufia.profile_path(@user.to_param), notice: "You are following #{@user}"
  end

  # Unfollow a user
  def unfollow
    if current_user.following?(@user)
      current_user.stop_following(@user)
      UserUnfollowEventJob.perform_later(current_user, @user)
    end
    redirect_to sufia.profile_path(@user.to_param), notice: "You are no longer following #{@user}"
  end

  def notifications_number
    @notify_number = 0
    return if action_name == "index" && controller_name == "mailbox"
    return unless user_signed_in?
    @notify_number = current_user.mailbox.inbox(unread: true).count
  end

  protected

    def user_params
      params.require(:user).permit(:email, :login, :display_name, :address, :admin_area,
                                   :department, :title, :office, :chat_id, :website, :affiliation,
                                   :telephone, :avatar, :group_list, :groups_last_update, :facebook_handle,
                                   :twitter_handle, :googleplus_handle, :linkedin_handle, :remove_avatar, :orcid)
    end

    # You can override base_query to return a list of arguments
    def base_query
      [nil]
    end

    def find_user
      @user = User.from_url_component(params[:id])
      redirect_to root_path, alert: "User '#{params[:id]}' does not exist" if @user.nil?
    end

    def user_not_current_user
      redirect_to sufia.profile_path(@user.to_param), alert: "You cannot follow or unfollow yourself" if @user == current_user
    end

    def sort_value
      sort = params[:sort].blank? ? "name" : params[:sort]
      case sort
      when 'name'
        'display_name'
      when 'name desc'
        'display_name DESC'
      else
        sort
      end
    end

    def deny_access(_exception)
      redirect_to sufia.profile_path(@user.to_param), alert: "Permission denied: cannot access this page."
    end
end
