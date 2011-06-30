require 'yaml'
class RoleMapper
  @@map = YAML.load(File.open(File.join(Rails.root, "config/role_map_#{Rails.env}.yml")))
  m = Hash.new{|h,k| h[k]=[]}
  @@byname = @@map.inject(m) do|memo, k| 
    k.last.each { |x| memo[x]<<k.first}
    memo
  end
  class << self
    def role_names
      @@map.keys
    end
    def roles(username)
      @@byname[username]||[]
    end
    
    def whois(r)
      @@map[r]||[]
    end
    
  end
end
