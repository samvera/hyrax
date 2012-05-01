module PSU
  module Noid
    def noid
      self.pid.split(":").last
    end
  end
end
