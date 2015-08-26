## This could extend from a module that would make it an ldap group
class Group
  def self.exists?(_cn)
    false
  end
end
