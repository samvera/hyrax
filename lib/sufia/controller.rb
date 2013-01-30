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

module Sufia::Controller
  extend ActiveSupport::Concern

  included do 
    # Adds Hydra behaviors into the application controller
    include Hydra::Controller::ControllerBehavior

    before_filter :notifications_number
    helper_method :groups

  end

  def current_ability
    current_user ? current_user.ability : super
  end

  def groups
    @groups ||= current_user ? current_user.groups : []
  end

  def render_404(exception)
    logger.error("Rendering 404 page due to exception: #{exception.inspect} - #{exception.backtrace if exception.respond_to? :backtrace}")
    render :template => '/error/404', :layout => "error", :formats => [:html], :status => 404
  end

  def render_500(exception)
    logger.error("Rendering 500 page due to exception: #{exception.inspect} - #{exception.backtrace if exception.respond_to? :backtrace}")
    render :template => '/error/500', :layout => "error", :formats => [:html], :status => 500
  end


  def notifications_number
    @notify_number=0
    @batches=[]
    return if action_name == "index" && controller_name == "mailbox"
    if current_user 
      @notify_number= current_user.mailbox.inbox(:unread => true).count(:id, :distinct => true)
      @batches=current_user.mailbox.inbox.map {|msg| msg.last_message.body[/<a class="batchid ui-helper-hidden">(.*)<\/a>The file(.*)/,1]}.select{|val| !val.blank?}
    end
  end

  protected

  ### Hook which is overridden in Sufia::Ldap::Controller
  def has_access?
    true
  end

  # include Sufia::HttpHeaderAuth

end
