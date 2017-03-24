module Hyrax::UsersControllerBehavior
  extend ActiveSupport::Concern

  included do
    include Blacklight::SearchContext
    prepend_before_action :find_user, only: [:show]

    helper Hyrax::TrophyHelper
  end

  def index
    @users = search(params[:uq])
  end

  # Display user profile
  def show
    user = User.from_url_component(params[:id])
    return redirect_to root_path, alert: "User '#{params[:id]}' does not exist" if user.nil?
    @presenter = Hyrax::UserProfilePresenter.new(user, current_ability)
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
      base.registered
          .where("#{Devise.authentication_keys.first} not in (?)",
                 [User.batch_user_key, User.audit_user_key])
          .references(:trophies)
          .order(sort_value)
          .page(params[:page]).per(10)
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
      when 'login'
        Devise.authentication_keys.first
      when 'login desc'
        "#{Devise.authentication_keys.first} DESC"
      else
        sort
      end
    end
end
