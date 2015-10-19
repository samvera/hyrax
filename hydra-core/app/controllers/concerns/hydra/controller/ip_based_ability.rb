module Hydra::Controller
  module IpBasedAbility
    # Overriding the default method provided by cancan
    # This passes the remote_ip to the Ability instance
    def current_ability
      @current_ability ||= ::Ability.new(current_user, remote_ip: request.remote_ip)
    end
  end
end
