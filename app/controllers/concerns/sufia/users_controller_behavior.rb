module Sufia::UsersControllerBehavior
  extend ActiveSupport::Concern

  included do
    include Blacklight::SearchContext
    with_themed_layout '1_column'
    prepend_before_action :find_user, except: [:index, :search, :notifications_number]
    before_action :authenticate_user!, only: [:edit, :update]
    authorize_resource only: [:edit, :update]
    # Catch permission errors
    rescue_from CanCan::AccessDenied, with: :deny_access
  end

  def index
    @users = search(params[:uq])
    respond_to do |format|
      format.html
      format.json { render json: @users.to_json }
    end
  end

  # Display user profile
  def show
    @presenter = Sufia::UserProfilePresenter.new(@user, current_ability)
  end

  # Display form for users to edit their profile information
  def edit
    @trophies = Sufia::TrophyPresenter.find_by_user(@user)
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

  def notifications_number
    @notify_number = 0
    return if action_name == "index" && controller_name == "mailbox"
    return unless user_signed_in?
    @notify_number = current_user.mailbox.inbox(unread: true).count
  end

  protected

    # TODO: this should move to a service.
    # Returns a list of users excluding the system users and guest_users
    # @param query [String] the query string
    def search(query)
      clause = query.blank? ? nil : "%" + query.downcase + "%"
      base = User.where(*base_query)
      unless clause.blank?
        base = base.where("#{Devise.authentication_keys.first} like lower(?) OR display_name like lower(?)", clause, clause)
      end
      base.where("#{Devise.authentication_keys.first} not in (?)",
                 [User.batch_user_key, User.audit_user_key])
          .where(guest: false)
          .references(:trophies)
          .order(sort_value)
          .page(params[:page]).per(10)
    end

    def user_params
      params.require(:user).permit(:avatar, :facebook_handle, :twitter_handle,
                                   :googleplus_handle, :linkedin_handle, :remove_avatar, :orcid)
    end

    # You can override base_query to return a list of arguments
    def base_query
      [nil]
    end

    def find_user
      @user = User.from_url_component(params[:id])
      redirect_to root_path, alert: "User '#{params[:id]}' does not exist" if @user.nil?
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
