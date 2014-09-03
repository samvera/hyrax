module CurationConcern
  module WithEditors
    extend ActiveSupport::Concern

    def add_editor_group(group_name)
      self.edit_groups += [group]
    end

    # @param groups [Array<String>] a list of group names to add
    def add_editor_groups(groups)
      groups.each { |g| add_editor_group(g) }
    end

    def remove_editor_group(group)
      self.edit_groups -= [group]
    end

    # @param groups [Array<String>] a list of users to remove
    def remove_editor_groups(groups)
      groups.each { |g| remove_editor_group(g) }
    end

    # @param user [String] the user account you want to grant edit access to.
    def add_editor(user)
      self.edit_users += [user]
    end

    # @param users [Array<String>] a list of users to add
    def add_editors(users)
      users.each { |u| add_editor(u) }
    end

    # @param user [String] the user account you want to revoke edit access for.
    def remove_editor(user)
      self.edit_users -= [user]
    end

    # @param users [Array<String>] a list of users to remove
    def remove_editors(users)
      users.each { |u| remove_editor(u) }
    end
  end
end

