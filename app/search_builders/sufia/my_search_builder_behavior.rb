# Behavior for the my controller search builder to allow the my controller to only get access to
# items I have edit access to.
#
# Separating as a behavior allows for easier overriding of the gem behavior.
module Sufia::MySearchBuilderBehavior
  extend ActiveSupport::Concern

  # show only files with edit permissions in lib/hydra/access_controls_enforcement.rb apply_gated_discovery
  def discovery_permissions
    ["edit"]
  end
end
