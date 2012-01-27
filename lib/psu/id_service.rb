module PSU
  class IdService
    @@minter = Noid::Minter.new(:template => '.reeddeeddk')
    @@namespace = "id:"
    def self.valid?(identifier)
      # remove the fedora namespace since it's not part of the noid
      identifier.slice!(@@namespace)
      @@minter.valid? identifier
    end
    def self.mint
      "#{@@namespace}#{@@minter.mint}"
    end    
  end
end
