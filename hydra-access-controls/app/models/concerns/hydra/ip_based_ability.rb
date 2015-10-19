module Hydra
  # include this on your ability class to add ip based groups to your user
  module IpBasedAbility

    def user_groups
      @user_groups ||= super + ip_based_groups
    end

    def ip_based_groups
      return [] unless options.key?(:remote_ip)
      IpBasedGroups.for(options.fetch(:remote_ip))
    end
  end
end
