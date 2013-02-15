module Hydra::PermissionsCache
  @@cache = {}

  def self.get(pid)
    @@cache[pid]
  end

  def self.put(pid, doc)
    @@cache[pid] = doc 
  end

  def self.clear
    @@cache = {}
  end

end
