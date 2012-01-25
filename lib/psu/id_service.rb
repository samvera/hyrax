require 'noid'

module PSU
  class IdService    
    def self.mint
      minter = Noid::Minter.new(:template => '.reeddeeddk')
      return "ark:/42409/#{minter.mint}"
    end    
  end
end
