# frozen_string_literal: true
module Hyrax
  ##
  # A simple data object for holding a user, work and their workflow proxies
  #
  # this is a glorified Struct that resolves +Sipity::Enitity(work)+
  # and +Sipity::Agent(user)+ for the input given, then provides readers
  # for its instance variables.
  #
  # @example
  #   info = WorkflowActionInfo.new(my_work, current_user)
  #
  #   info.agent # =>  #<Sipity::Agent...>
  #   info.entity # =>  #<Sipity::Entity...>
  #   info.work == my_work # => true
  #   info.user == current_user # => true
  class WorkflowActionInfo
    ##
    # @param work [Object]
    # @param user [::User]
    def initialize(work, user)
      @work = work
      @user = user
      @entity = Sipity::Entity(work)
      @agent = Sipity::Agent(user)
    end

    attr_reader :entity, :agent, :user, :work
  end
end
