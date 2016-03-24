# Include this module into any of your Controller classes to add Hydra functionality
#
# @example
#  class CustomHydraController < ApplicationController
#    include Hydra::Controller::ControllerBehavior
#  end
#
module Hydra::Controller::ControllerBehavior
  extend ActiveSupport::Concern

  included do
    # Catch permission errors
    rescue_from CanCan::AccessDenied, with: :deny_access
  end

  # get the currently configured user identifier.  Can be overridden to return whatever (ie. login, email, etc)
  # defaults to using whatever you have set as the Devise authentication_key
  def user_key
    current_user.user_key if current_user
  end

  # Override this method if you wish to customize the way access is denied
  def deny_access(exception)
    if exception.action == :edit
      redirect_to(main_app.url_for(action: 'show'), alert: exception.message)
    elsif current_user and current_user.persisted?
      redirect_to main_app.root_path, alert: exception.message
    else
      session['user_return_to'.freeze] = request.url
      redirect_to main_app.new_user_session_path, alert: exception.message
    end
  end

  module ClassMethods
    # get the solr name for a field with this name and using the given solrizer descriptor
    def solr_name(name, *opts)
      ActiveFedora.index_field_mapper.solr_name(name, *opts)
    end
  end
end
