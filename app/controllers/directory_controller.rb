class DirectoryController < ApplicationController
  include Hydra::Controller::ControllerBehavior

  # returns true if the user exists and false otherwise
  def user
    render :json => User.attributes(params[:uid])
  end

  def user_attribute
    if params[:attribute] == "groups"
      res = User.groups(params[:uid])
    else
      res = User.attributes(params[:uid], params[:attribute])
    end
    render :json => res
  end

  def user_groups
    render :json => User.groups(params[:uid])
  end

  def group
    puts params[:cn]
    render :json => Hydra::LDAP.does_group_exist?(params[:cn])
  end
end
