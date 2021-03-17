# frozen_string_literal: true

##
# A fake group service implementation for use in test suites as a drop-in
# replacement for `RoleMapper` or the `hydra-role-management` gem, allowing
# dynamic group assignment backed by in-memory data structures.
#
# @example setup the group service for an rspec test suite
#   config.before(:suite) do
#     ::User.group_service = TestHydraGroupService.new
#   end
#
# @example adding a user to a group
#   ::User.group_service.add(user: my_user, groups: ['a_group'])
#
# @example clearing the user -> group map
#   ::User.group_service.clear
#
# @see Hydra::User.group_service
class TestHydraGroupService
  ##
  # @param group_map [Hash{String, Array<String>}] map user keys to group names
  def initialize(group_map: {})
    @group_map = group_map
  end

  ##
  # @param user [::User]
  # @param groups [Array<String>, String]
  #
  # @return [void]
  def add(user:, groups:)
    @group_map[user.user_key] = fetch_groups(user: user) + Array(groups)
  end

  ##
  # @return [void]
  def clear
    @group_map = {}
  end

  ##
  # @param user [::User]
  #
  # @return [Array<String>]
  def fetch_groups(user:)
    @group_map.fetch(user.user_key) { [] }
  end

  ##
  # @return [Array<String>] a list of all known group names
  def role_names
    @group_map.values.flatten.uniq
  end
end
