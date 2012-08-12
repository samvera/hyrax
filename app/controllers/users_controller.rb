class UsersController < ApplicationController
  prepend_before_filter :find_user
  before_filter :authenticate_user!, only: [:edit, :update, :follow, :unfollow]
  before_filter :user_is_current_user, only: [:edit, :update]
  before_filter :user_not_current_user, only: [:follow, :unfollow]

  # Display user profile
  def show
    @followers = @user.followers
    @following = @user.all_following
  end

  # Display form for users to edit their profile information
  def edit
  end

  # Process changes from profile form
  def update
    @user.populate_attributes if params[:update_directory]
    @user.avatar = params[:user][:avatar] if params[:user][:avatar].present? rescue nil
    @user.avatar = nil if params[:delete_avatar]
    unless @user.save
      redirect_to edit_profile_path(@user.to_s), alert: @user.errors.full_messages
      return
    end
    begin
      Resque.enqueue(UserEditProfileEventJob, @user.login)
    rescue Redis::CannotConnectError
      logger.error "Redis is down!"
    end
    redirect_to profile_path(@user.to_s), notice: "Your profile has been updated"
  end

  # Follow a user
  def follow
    unless current_user.following?(@user)
      current_user.follow(@user)
      begin
        Resque.enqueue(UserFollowEventJob, current_user.login, @user.login)
      rescue Redis::CannotConnectError
        logger.error "Redis is down!"
      end
    end
    redirect_to profile_path(@user.to_s), notice: "You are following #{@user.to_s}"
  end

  # Unfollow a user
  def unfollow
    if current_user.following?(@user)
      current_user.stop_following(@user)
      begin
        Resque.enqueue(UserUnfollowEventJob, current_user.login, @user.login)
      rescue Redis::CannotConnectError
        logger.error "Redis is down!"
      end
    end
    redirect_to profile_path(@user.to_s), notice: "You are no longer following #{@user.to_s}"
  end

  private
  def find_user
    @user = User.find_by_login(params[:uid])
    redirect_to root_path, alert: "User '#{params[:uid]}' does not exist" if @user.nil?
  end

  def user_is_current_user
    redirect_to profile_path(@user.to_s), alert: "You cannot edit #{@user.to_s}\'s profile" unless @user == current_user
  end

  def user_not_current_user
    redirect_to profile_path(@user.to_s), alert: "You cannot follow or unfollow yourself" if @user == current_user
  end
end
