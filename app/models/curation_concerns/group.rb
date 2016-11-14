module CurationConcerns
  class Group
    def initialize(name)
      @name = name
    end

    attr_reader :name

    def to_sipity_agent
      sipity_agent || create_sipity_agent!
    end

    private

      def sipity_agent
        Sipity::Agent.find_by(proxy_for_id: name, proxy_for_type: self.class.name)
      end

      def create_sipity_agent!
        Sipity::Agent.create!(proxy_for_id: name, proxy_for_type: self.class.name)
      end
  end
end
