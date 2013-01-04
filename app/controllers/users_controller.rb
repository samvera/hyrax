# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class UsersController < ApplicationController
  prepend_before_filter :find_user, :except => [:index, :search, :notifications_number]
  before_filter :authenticate_user!, only: [:edit, :update, :follow, :unfollow]
  before_filter :user_is_current_user, only: [:edit, :update]
  before_filter :user_not_current_user, only: [:follow, :unfollow]

  def index
    sort_val = get_sort
    query = params[:uq].blank? ? nil : "%"+params[:uq].downcase+"%"
    if query.blank?
      @users = User.order(sort_val).page(params[:page]).per(10) if query.blank? 
    else
      @users = User.where("(login like lower(?) OR display_name like lower(?))",query,query).order(sort_val).page(params[:page]).per(10)
    end
  end

  # Display user profile
  def show
    if @user.respond_to? :profile_events
      @events = @user.profile_events(100) 
    else 
      @events = []
    end
    @followers = @user.followers
    @following = @user.all_following
  end

  # Display form for users to edit their profile information
  def edit
    @user = current_user
    @groups = @user.groups
  end

  # Process changes from profile form
  def update
    @user.update_attributes(params[:user])
  
    @user.populate_attributes if params[:update_directory]
    @user.avatar = nil if params[:delete_avatar]
    unless @user.save
      redirect_to sufia.edit_profile_path(URI.escape(@user.to_s,'@.')), alert: @user.errors.full_messages
      return
    end
    Sufia.queue.push(UserEditProfileEventJob.new(@user.user_key))
    redirect_to sufia.profile_path(URI.escape(@user.to_s,'@.')), notice: "Your profile has been updated"
  end

  # Follow a user
  def follow
    unless current_user.following?(@user)
      current_user.follow(@user)
      Sufia.queue.push(UserFollowEventJob.new(current_user.user_key, @user.user_key))
    end
    redirect_to sufia.profile_path(URI.escape(@user.to_s,'@.')), notice: "You are following #{@user.to_s}"
  end

  # Unfollow a user
  def unfollow
    if current_user.following?(@user)
      current_user.stop_following(@user)
      Sufia.queue.push(UserUnfollowEventJob.new(current_user.user_key, @user.user_key))
    end
    redirect_to sufia.profile_path(URI.escape(@user.to_s,'@.')), notice: "You are no longer following #{@user.to_s}"
  end

  private
  def find_user
    @user = User.find_by_user_key(params[:uid])
    redirect_to root_path, alert: "User '#{params[:uid]}' does not exist" if @user.nil?
  end

  def user_is_current_user
    redirect_to sufia.profile_path(URI.escape(@user.to_s,'@.')), alert: "You cannot edit #{@user.to_s}\'s profile" unless @user == current_user
  end

  def user_not_current_user
    redirect_to sufia.profile_path(URI.escape(@user.to_s,'@.')), alert: "You cannot follow or unfollow yourself" if @user == current_user
  end

  def get_sort
    sort = params[:sort].blank? ? "name" : params[:sort]
    sort_val = case sort
           when "name"  then "display_name"
           when "name desc"   then "display_name DESC"
           else sort
           end
    return sort_val
  end
end
