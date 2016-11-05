module CurationConcerns
  # A simple data object for holding a user, work and their workflow proxies
  class WorkflowActionInfo
    def initialize(work, user)
      @work = work
      @user = user
      @entity = PowerConverter.convert(work, to: :sipity_entity)
      @agent = PowerConverter.convert(user, to: :sipity_agent)
    end

    attr_reader :entity, :agent, :user, :work
  end
end
