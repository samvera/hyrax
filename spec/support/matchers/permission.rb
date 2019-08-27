# frozen_string_literal: true

RSpec::Matchers.define :grant_permission do |acl_type|
  match do |permission|
    access_match = permission.access == acl_type.to_s

    agent_match =
      if user_id
        permission.type == 'person' &&
          permission.agent.first.id.include?(user_id.to_s)
      elsif group_id
        permission.type == 'group' &&
          permission.agent.first.id.include?(group_id.to_s)
      else
        true
      end

    target_match =
      if access_to_id
        permission.access_to_id == access_to_id.to_s
      else
        true
      end

    return access_match && agent_match && target_match
  end

  chain :on,       :access_to_id
  chain :to_user,  :user_id
  chain :to_group, :group_id
end
