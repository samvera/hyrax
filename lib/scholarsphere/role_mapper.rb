class RoleMapper
  def self.roles(uid)
    u = User.find_by_login(uid)
    return [] unless u
    u.groups
  end
end
