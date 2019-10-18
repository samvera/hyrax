module Hyrax
  # A simple data object for holding a user, work and their workflow proxies
  class WorkflowActionInfo
    def initialize(work, user)
      @work = work
      @user = user
      @entity = Sipity::Entity(work)
      @agent = PowerConverter.convert(user, to: :sipity_agent)
    end

    attr_reader :entity, :agent, :user, :work
  end
end
