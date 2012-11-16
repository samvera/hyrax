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
  before_filter :authenticate_user!, only: [:edit, :update, :follow, :unfollow, :toggle_trophy]
  before_filter :user_is_current_user, only: [:edit, :update, :toggle_trophy]

  before_filter :user_not_current_user, only: [:follow, :unfollow]

  def index
    sort_val = get_sort
    query = params[:uq].blank? ? nil : "%"+params[:uq].downcase+"%"
    @users = User.where("(login like lower(?) OR display_name like lower(?)) and ldap_available = true ",query,query).paginate(:page => params[:page], 
                           :per_page => 10, :order => sort_val) unless query.blank?   
    @users = User.where("ldap_available = true").paginate(:page => params[:page], :per_page => 10, :order => sort_val) if query.blank?
  end

  # Display user profile
  def show
    if @user.respond_to? :profile_events
      @events = @user.profile_events(100) 
    else 
      @events = []
    end
    @trophies=[]
    @user.trophies.each do |t| 
      @trophies << GenericFile.find("scholarsphere:#{t.generic_file_id}")
    end
    @followers = @user.followers
    @following = @user.all_following
  end

  # Display form for users to edit their profile information
  def edit
    @user = current_user
    @groups = @user.groups
    @trophies=[]
    @user.trophies.each do |t| 
      @trophies << GenericFile.find("scholarsphere:#{t.generic_file_id}")
    end
  end

  # Process changes from profile form
  def update
    @user.update_attributes(params[:user])
  
    @user.populate_attributes if params[:update_directory]
    @user.avatar = nil if params[:delete_avatar]
    unless @user.save
      redirect_to edit_profile_path(@user.to_s), alert: @user.errors.full_messages
      return
    end
    delete_trophy = params.keys.reject{|k,v|k.slice(0,'remove_trophy'.length)!='remove_trophy'}
    delete_trophy = delete_trophy.map{|v| v.slice('remove_trophy_'.length..-1)}
    delete_trophy.each do | smash_trophy |
      Trophy.where(user_id: current_user.id, generic_file_id: smash_trophy.slice('scholarsphere:'.length..-1)).each.map(&:delete)
    end
    begin
      Resque.enqueue(UserEditProfileEventJob, @user.login)
    rescue Redis::CannotConnectError
      logger.error "Redis is down!"
    end
    redirect_to profile_path(@user.to_s), notice: "Your profile has been updated"
  end
  def toggle_trophy    
     unless current_user.can? :edit, permissions_solr_doc_for_id("scholarsphere:#{params[:file_id]}")
       return false
     end
     # TO DO  make sure current user has access to file
     t = Trophy.where(:generic_file_id => params[:file_id], :user_id => current_user.id).first
     if t.blank? 
       t = Trophy.create(:generic_file_id => params[:file_id], :user_id => current_user.id)
       return false unless t.persisted?
     else
       t.delete  
       #TODO do this better says Mike
       return false if t.persisted?  
     end
     render :json => t
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
    redirect_to profile_path(@user.to_s), alert: "Permission denied: cannot access this page." unless @user == current_user
  end

  def user_not_current_user
    redirect_to profile_path(@user.to_s), alert: "You cannot follow or unfollow yourself" if @user == current_user
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
