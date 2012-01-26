module PSU
  class IdService    
    @@xdigits = Noid::XDIGIT.join
    def self.valid?(identifier)
      identifier =~ /^id:[#@@xdigits]{2}\d{2}[#@@xdigits]{2}\d{2}[#@@xdigits]$/
    end
    def self.mint
      minter = Noid::Minter.new(:template => '.reeddeeddk')
      return "id:#{minter.mint}"
    end    
  end
end
