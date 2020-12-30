# frozen_string_literal: true
module Hyrax
  class UsersController < ApplicationController
    include Blacklight::SearchContext
    prepend_before_action :find_user, only: [:show]

    helper Hyrax::TrophyHelper

    def index
      authenticate_user! if Flipflop.hide_users_list?
      @users = search(params[:uq])
    end

    # Display user profile
    def show
      user = ::User.from_url_component(params[:id])
      return redirect_to root_path, alert: "User '#{params[:id]}' does not exist" if user.nil?
      @presenter = Hyrax::UserProfilePresenter.new(user, current_ability)
    end

    private

    ##
    # @param query [String] the query string
    #
    # @return [Enumerable] a list of users excluding the system users and guest_users
    def search(query)
      base = ::User
      clause = query.blank? ? nil : "%#{base.sanitize_sql_like(query.downcase)}%"
      base = base.where(*Array.wrap(base_query))
      # This may have some DB adapter specific behavior.
      base = base.where("LOWER(#{base.user_key_field}) LIKE :clause OR LOWER(display_name) LIKE :clause", clause: clause) if clause.present?
      base.registered
          .without_system_accounts
          .references(:trophies)
          .order(sort_value)
          .page(params[:page]).per(10)
    end

    # @api public
    #
    # You can override base_query to return a list of arguments
    #
    # @note This changed a default from `[nil]` to `{}`.  In part
    # there were errors in the specs regarding this behavior.
    #
    # @example
    #   def base_query
    #     { custom_field: true }
    #   end
    #
    # @return Hash (or more appropriate something that maps to the
    # method signature of ActiveRecord::Base.where)
    def base_query
      {}
    end

    def find_user
      @user = ::User.from_url_component(params[:id])
      redirect_to root_path, alert: "User does not exist" unless @user
    end

    def sort_value
      sort = params[:sort].presence || "name"
      case sort
      when 'name'
        'display_name'
      when 'name desc'
        'display_name DESC'
      when 'login'
        Hydra.config.user_key_field
      when 'login desc'
        "#{Hydra.config.user_key_field} DESC"
      else
        sort
      end
    end
  end
end
