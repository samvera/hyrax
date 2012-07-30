class UsersController < ApplicationController
  prepend_before_filter :find_user
  before_filter :authenticate_user!, :only => [:edit, :update, :follow, :unfollow]
  before_filter :user_is_current_user, :only => [:edit, :update]

  # Display user profile
  def show
    # TODO: flesh this out
  end

  # Display form for users to edit their profile information
  def edit
    # TODO: flesh this out
  end

  # Process changes from profile form
  def update
    # TODO: flesh this out
  end

  # Follow a user
  def follow
    current_user.follow(@user) unless current_user.following?(@user)
    redirect_to profile_path(@user.to_s), :notice => "You are following #{@user.to_s}"
  end

  # Unfollow a user
  def unfollow
    current_user.stop_following(@user) if current_user.following?(@user)
    redirect_to profile_path(@user.to_s), :notice => "You are no longer following #{@user.to_s}"
  end

  private
  def find_user
    @user = User.find_by_login(params[:uid])
    redirect_to root_path, :alert => "User '#{params[:uid]}' does not exist" if @user.nil?
  end

  def user_is_current_user
    redirect_to profile_path(@user.to_s), :alert => "You cannot edit #{@user.to_s}\'s profile" unless @user == current_user
  end
end
