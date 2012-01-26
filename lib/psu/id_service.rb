require 'noid'

module PSU
  class IdService    
    def self.mint
      minter = Noid::Minter.new(:template => '.reeddeeddk')
      return "id:#{minter.mint}"
    end    
  end
end
