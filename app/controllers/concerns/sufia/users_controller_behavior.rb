module Sufia::UsersControllerBehavior
  extend ActiveSupport::Concern

  included do
    layout "sufia-one-column"
    prepend_before_filter :find_user, :except => [:index, :search, :notifications_number]
    before_filter :authenticate_user!, only: [:edit, :update, :follow, :unfollow, :toggle_trophy]
    before_filter :user_is_current_user, only: [:edit, :update, :toggle_trophy]

    before_filter :user_not_current_user, only: [:follow, :unfollow]
  end

  def index
    sort_val = get_sort
    query = params[:uq].blank? ? nil : "%"+params[:uq].downcase+"%"
    base = User.where(*base_query)
    unless query.blank?
      base = base.where("#{Devise.authentication_keys.first} like lower(?) OR display_name like lower(?)", query, query)
    end
    @users = base.order(sort_val).page(params[:page]).per(10)

    respond_to do |format|
      format.html
      format.json { render json: @users.to_json }
    end
    
  end

  # Display user profile
  def show
    if @user.respond_to? :profile_events
      @events = @user.profile_events(100) 
    else 
      @events = []
    end
    @trophies = @user.trophy_ids
    @followers = @user.followers
    @following = @user.all_following
  end

  # Display form for users to edit their profile information
  def edit
    @user = current_user
    @trophies = @user.trophy_ids
  end

  # Process changes from profile form
  def update
    if params[:user]
      if Rails::VERSION::MAJOR == 3
        @user.update_attributes(params[:user])
      else
        @user.update_attributes(params.require(:user).permit(*User.permitted_attributes))
      end
    end
    @user.populate_attributes if params[:update_directory]
    @user.avatar = nil if params[:delete_avatar]
    unless @user.save
      redirect_to sufia.edit_profile_path(URI.escape(@user.to_s,'@.')), alert: @user.errors.full_messages
      return
    end
    delete_trophy = params.keys.reject{|k,v|k.slice(0,'remove_trophy'.length)!='remove_trophy'}
    delete_trophy = delete_trophy.map{|v| v.slice('remove_trophy_'.length..-1)}
    delete_trophy.each do | smash_trophy |
      Trophy.where(user_id: current_user.id, generic_file_id: smash_trophy).each.map(&:delete)
    end
    Sufia.queue.push(UserEditProfileEventJob.new(@user.user_key))
    redirect_to sufia.profile_path(URI.escape(@user.to_s,'@.')), notice: "Your profile has been updated"
  end

  def toggle_trophy    
     id = params[:file_id]
     id = "#{Sufia.config.id_namespace}:#{id}" unless id.include?(":")
     unless current_user.can? :edit, id
       redirect_to root_path, alert: "You do not have permissions to the file"
       return false
     end
     # TODO  make sure current user has access to file
     t = Trophy.where(:generic_file_id => params[:file_id], :user_id => current_user.id).first
     if t.blank? 
       t = Trophy.create(:generic_file_id => params[:file_id], :user_id => current_user.id)
       return false unless t.persisted?
     else
       t.destroy  
       #TODO do this better says Mike
       return false if t.persisted?  
     end
     render :json => t
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

  protected

  # You can override base_query to return a list of arguments 
  def base_query
    [nil]
  end

  def find_user
    @user = User.from_url_component(params[:id])
    redirect_to root_path, alert: "User '#{params[:id]}' does not exist" if @user.nil?
  end

  def user_is_current_user
    redirect_to sufia.profile_path(URI.escape(@user.to_s,'@.')), alert: "Permission denied: cannot access this page." unless @user == current_user
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

