module Sufia::UsersControllerBehavior
  extend ActiveSupport::Concern

  included do
    include Blacklight::Catalog::SearchContext
    layout "sufia-one-column"
    prepend_before_filter :find_user, except: [:index, :search, :notifications_number]
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
    @users = base.references(:trophies).order(sort_val).page(params[:page]).per(10)

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
    @trophies = @user.trophy_files
    @followers = @user.followers
    @following = @user.all_following
  end

  # Display form for users to edit their profile information
  def edit
    @user = current_user
    @trophies = @user.trophy_files
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
    # TODO this should be moved to TrophiesController
    params.keys.select {|k, v| k.starts_with? 'remove_trophy_' }.each do |smash_trophy|
      smash_trophy = smash_trophy.sub /^remove_trophy_/, ''
      current_user.trophies.where(generic_file_id: smash_trophy).destroy_all
    end
    Sufia.queue.push(UserEditProfileEventJob.new(@user.user_key))
    redirect_to sufia.profile_path(@user.to_param), notice: "Your profile has been updated"
  end

  def update_directory?
    ['1', 'true'].include? params[:user][:update_directory]
  end

  def toggle_trophy
     unless current_user.can? :edit, params[:file_id]
       redirect_to root_path, alert: "You do not have permissions to the file"
       return false
     end
     # TODO  make sure current user has access to file
     t = current_user.trophies.where(generic_file_id: params[:file_id]).first
     if t
       t.destroy
       #TODO do this better says Mike
       return false if t.persisted?
     else
       t = current_user.trophies.create(generic_file_id: params[:file_id])
       return false unless t.persisted?
     end
     render json: t
  end

  # Follow a user
  def follow
    unless current_user.following?(@user)
      current_user.follow(@user)
      Sufia.queue.push(UserFollowEventJob.new(current_user.user_key, @user.user_key))
    end
    redirect_to sufia.profile_path(@user.to_param), notice: "You are following #{@user.to_s}"
  end

  # Unfollow a user
  def unfollow
    if current_user.following?(@user)
      current_user.stop_following(@user)
      Sufia.queue.push(UserUnfollowEventJob.new(current_user.user_key, @user.user_key))
    end
    redirect_to sufia.profile_path(@user.to_param), notice: "You are no longer following #{@user.to_s}"
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

  def user_is_current_user
    redirect_to sufia.profile_path(@user.to_param), alert: "Permission denied: cannot access this page." unless @user == current_user
  end

  def user_not_current_user
    redirect_to sufia.profile_path(@user.to_param), alert: "You cannot follow or unfollow yourself" if @user == current_user
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
